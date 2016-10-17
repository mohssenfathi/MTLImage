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
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
        
    func setup() {
        
        device = input?.context.device
        delegate = self
        clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
        framebufferOnly = false
        autoResizeDrawable = false
        contentMode = .scaleAspectFit
    }
    
    func inputChanged() {
        
        device = internalInput?.context.device
        reload()
        
        if let context = input?.context {
            let continuous = context.continuousUpdate
            enableSetNeedsDisplay = !continuous
            isPaused = !continuous
        }
        
        draw()
    }
    
    func reload() {
        
        guard let library = input?.context.library else { return }
        
        vertexFunction   = library.makeFunction(name: "vertex_main")
        fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
        
        vertexBuffer = device?.makeBuffer(bytes: kQuadVertices , length: kSzQuadVertices , options: MTLResourceOptions())
        if texCoordBuffer == nil {
            texCoordBuffer = device?.makeBuffer(bytes: kQuadTexCoords, length: kSzQuadTexCoords, options: MTLResourceOptions())
        }
        
    }

    
    // MARK: - Properties
    
    public var mtlViewDelegate: MTLViewDelegate?
    
    private var privateIdentifier: String = UUID().uuidString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
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
    
    public var title: String  = "MTLView"
    
    
    let renderSemaphore = DispatchSemaphore(value: 3)
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!

    
    let kSzQuadTexCoords = 6 * MemoryLayout<float2>.size
    let kSzQuadVertices  = 6 * MemoryLayout<float4>.size
    
    let kQuadTexCoords: [float2] = [ float2(0.0, 0.0),
                                     float2(1.0, 0.0),
                                     float2(0.0, 1.0),
                                     
                                     float2(1.0, 0.0),
                                     float2(0.0, 1.0),
                                     float2(1.0, 1.0) ]
    
    var kQuadVertices: [float4] = [ float4(-1.0,  1.0, 0.0, 1.0),
                                    float4( 1.0,  1.0, 0.0, 1.0),
                                    float4(-1.0, -1.0, 0.0, 1.0),
                                    
                                    float4( 1.0,  1.0, 0.0, 1.0),
                                    float4(-1.0, -1.0, 0.0, 1.0),
                                    float4( 1.0, -1.0, 0.0, 1.0) ]
    
    
}


extension MTLView: MTKViewDelegate {
    
    public func draw(in view: MTKView) {
        
        guard let commandQueue = input?.context.commandQueue, let texture = input?.texture, let drawable = view.currentDrawable else {
                return
        }
        
        if texture.width != Int(drawableSize.width) || texture.height != Int(drawableSize.height) {
            drawableSize = CGSize(width: texture.width, height: texture.height)
            return
        }
        

        if let renderPassDescriptor = view.currentRenderPassDescriptor {

            renderSemaphore.wait()
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
            commandEncoder.setVertexBuffer(self.texCoordBuffer, offset: 0, at: 1)
            commandEncoder.setFragmentTexture(texture, at: 0)
            commandEncoder.drawPrimitives(type: .triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
            commandEncoder.endEncoding()
            
            commandBuffer.addCompletedHandler({ (buffer) in
                self.renderSemaphore.signal()
            })

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
//        let commandBuffer = commandQueue.makeCommandBuffer()
//
//        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
//        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
//                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
//                         sourceSize: MTLSize(width: texture.width, height: texture.height, depth: texture.depth),
//                         to: drawable.texture, destinationSlice: 0, destinationLevel: 0,
//                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
//        blitEncoder.endEncoding()
//
//        commandBuffer.present(drawable)
//        commandBuffer.commit()
        
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
