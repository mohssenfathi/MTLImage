//
//  View.swift
//  MTLImage_macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation
import MetalKit

public
class View: MTKView, Output {

    public init(frame frameRect: CGRect) {
        super.init(frame: frameRect, device: nil)
        setup()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        
        device = input?.context.device
//        delegate = self
        framebufferOnly = false
        autoResizeDrawable = false
        layerContentsPlacement = .scaleProportionallyToFit
        preferredFramesPerSecond = 60
        layer?.isOpaque = false
    }
    
    func reload() {
        
        device = input?.context.device
        
        if let texture = input?.texture {
            drawableSize = CGSize(width: texture.width, height: texture.height)
        }
        
//        setupRenderView()
//        return
        
        guard let library = input?.context.library else { return }
        
        vertexFunction   = library.makeFunction(name: "vertex_main")
        fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    func setupRenderView() {
        
        guard let library = input?.context.library else { return }
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perPatchControlPoint
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stride = 4 * MemoryLayout<Float>.size
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.sampleCount = sampleCount
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        renderPipelineDescriptor.vertexFunction   = library.makeFunction(name: "vertex_main")

        do {
            pipeline = try device?.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
    
    }
    
    // MARK: - Output
    public var title: String = "View"
    public var id: String = UUID().uuidString
    public var input: Input? {
        didSet { reload() }
    }
    
    let semaphore = DispatchSemaphore(value: 3)
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    var contentSize: CGSize = .zero

    private var lastTime = CACurrentMediaTime()
}

extension View {
    
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
    
    public override func draw(_ dirtyRect: NSRect) {
        
        notifyOtherTargets()
        
        input?.processIfNeeded()
        
        guard let commandQueue = input?.context.commandQueue,
            let texture = input?.texture,
            let drawable = currentDrawable else {
                return
        }
        
        if texture.width != Int(drawableSize.width) || texture.height != Int(drawableSize.height) {
            drawableSize = CGSize(width: texture.width, height: texture.height)
            contentSize = drawableSize
            return
        }
        
        if let renderPassDescriptor = currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            
            commandEncoder.pushDebugGroup("Render View")
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            commandEncoder.endEncoding()
            commandEncoder.popDebugGroup()
            
            commandBuffer.addCompletedHandler({ (buffer) in
                self.semaphore.signal()
                self.updateTime()
            })
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
//            commandBuffer.waitUntilCompleted()
        }

        
    }
    
    func updateTime() {
        let diff = CACurrentMediaTime() - lastTime
        lastTime = CACurrentMediaTime()
        print("\(Int(diff * 1000.0)) ms")
    }
}
