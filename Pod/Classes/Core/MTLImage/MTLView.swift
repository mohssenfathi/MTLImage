//
//  MTLView.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/13/16.
//
//

import UIKit
import MetalKit

public
protocol MTLViewDelegate {
    func mtlViewTouchesBegan(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesMoved(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesEnded(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
}

public
class MTLView: MTKView, MTLOutput {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: nil)
    }
        
    func setup() {
        
        device = input?.context.device
        delegate = self
        clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
        framebufferOnly = false
        autoResizeDrawable = false
        contentMode = .scaleAspectFit
//        enableSetNeedsDisplay = true
//        isPaused = true

    }
    
    func inputChanged() {
        device = internalInput?.context.device
        
//        if let context = input?.context {
//            let continuous = context.continuousUpdate
//            enableSetNeedsDisplay = !continuous
//            isPaused = !continuous
//        }
//        
//        draw()
    }
    
    public var mtlViewDelegate: MTLViewDelegate?
    
    private var privateIdentifier: String = UUID().uuidString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    public var title: String  = "MTLView"
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private var internalInput: MTLInput?
    public var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            internalInput = newValue
            inputChanged()
        }
    }
    
}



extension MTLView: MTKViewDelegate {
    
    public func draw(in view: MTKView) {
        
        guard let commandQueue = input?.context.commandQueue,
            let texture = input?.texture,
            let drawable = view.currentDrawable else {
                return
        }
        
        if texture.width != Int(drawableSize.width) || texture.height != Int(drawableSize.height) {
            drawableSize = CGSize(width: texture.width, height: texture.height)
            return
        }
        
//        if let renderPassDescriptor = view.currentRenderPassDescriptor {
//            
//            let commandBuffer = commandQueue.makeCommandBuffer()
//            
//            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
//            renderPassDescriptor.colorAttachments[0].loadAction = .clear
//            renderPassDescriptor.colorAttachments[0].texture = texture
//            
//            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
//            commandEncoder.endEncoding()
//            
//            commandBuffer.present(drawable)
//            commandBuffer.commit()
//        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSize(width: texture.width, height: texture.height, depth: texture.depth),
                         to: drawable.texture, destinationSlice: 0, destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    

}

extension MTLView {
    
    //    MARK: - Touch Events
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        mtlViewDelegate?.mtlViewTouchesBegan(self, touches: touches, event: event)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        mtlViewDelegate?.mtlViewTouchesMoved(self, touches: touches, event: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        mtlViewDelegate?.mtlViewTouchesEnded(self, touches: touches, event: event)
    }
}
