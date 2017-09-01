//
//  View.swift
//  MTLImage_macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation
import MetalKit

public
class View: NSView, Output {

    var mtkView: MTLMTKView!

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    func setup() {
        mtkView = MTLMTKView(frame: bounds, device: input?.context.device)
        mtkView.autoresizingMask = [.width, .height]
        mtkView.hostView = self
        mtkView.delegate = self
        addSubview(mtkView)
    }
    
    func reload() {
        
        guard let input = input else { return }
        
        mtkView.device = input.context.device
        
        if let texture = input.texture {
            mtkView.drawableSize = CGSize(width: texture.width, height: texture.height)
        }
        
        vertexFunction   = input.context.library.makeFunction(name: "vertex_main")
        fragmentFunction = input.context.library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try input.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    func notifyOtherTargets() {
        for var destination in (source?.destinations ?? []) {
            if destination.id != id {
                if var object = destination as? MTLObject {
                    object.setNeedsUpdate()
                    object.processIfNeeded()
                } else {
                    destination.input?.setNeedsUpdate()
                    destination.input?.processIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Output
    public var title: String = "View"
    public var id: String = UUID().uuidString
    public var input: Input? {
        didSet { reload() }
    }
    
    var contentSize: CGSize = .zero
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    
    fileprivate let semaphore = DispatchSemaphore(value: 3)
    fileprivate var lastTime = CACurrentMediaTime()
}

extension View: MTKViewDelegate {
    
    public func draw(in view: MTKView) {
        
        guard let input = input else { return }
        
        notifyOtherTargets()
        input.processIfNeeded()
        
        guard let commandQueue = input.context.commandQueue,
            let texture = input.texture,
            let drawable = view.currentDrawable else {
                return
        }
        
        if texture.width != Int(view.drawableSize.width) || texture.height != Int(view.drawableSize.height) {
            view.drawableSize = CGSize(width: texture.width, height: texture.height)
            return
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
        }
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.pushDebugGroup("Render View")
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            commandEncoder.endEncoding()
            commandEncoder.popDebugGroup()
        }
        
        //        if let blit = commandBuffer.makeBlitCommandEncoder() {
        //            blit.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
        //                      sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
        //                      sourceSize: texture.size(),
        //                      to: drawable.texture, destinationSlice: 0, destinationLevel: 0,
        //                      destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        //            blit.synchronize(texture: texture, slice: 0, level: 0)
        //            blit.endEncoding()
        //        }
        
        commandBuffer.addCompletedHandler({ (buffer) in
            self.semaphore.signal()
            self.updateTime()
        })
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        //        commandBuffer.waitUntilCompleted()
        
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func updateTime() {
        let diff = CACurrentMediaTime() - lastTime
        lastTime = CACurrentMediaTime()
        print("\(Int(diff * 1000.0)) ms")
    }
}

class MTLMTKView: MTKView {
    
    weak var hostView: View!
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        framebufferOnly = false
        autoResizeDrawable = false
        layerContentsPlacement = .scaleProportionallyToFit
        preferredFramesPerSecond = 60
        layer?.isOpaque = false
    }
    
}

