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

    public var mtkView: MTLMTKView!

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

        vertexFunction   = input.context.library?.makeFunction(name: "vertex_main")
        fragmentFunction = input.context.library?.makeFunction(name: "fragment_main")

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
        render()
    }

    func render() {
        guard let input = input else { return }

        notifyOtherTargets()
        input.processIfNeeded()

        guard let commandQueue = input.context.commandQueue,
            let texture = input.texture,
            let drawable = mtkView.currentDrawable else {
                return
        }
        
        if texture.width != Int(mtkView.drawableSize.width) || texture.height != Int(mtkView.drawableSize.height) {
            mtkView.drawableSize = CGSize(width: texture.width, height: texture.height)
            return
        }

        guard let renderPassDescriptor = mtkView.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
        }

        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.pushDebugGroup("Render View")
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            commandEncoder.endEncoding()
            commandEncoder.popDebugGroup()
        }

        commandBuffer.addCompletedHandler({ (buffer) in
//            self.updateTime()
        })

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    func updateTime() {
        let diff = CACurrentMediaTime() - lastTime
        lastTime = CACurrentMediaTime()
        print("\(Int(diff * 1000.0)) ms")
    }
}

public
class MTLMTKView: MTKView {

    weak var hostView: View!

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }

    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public override func layout() {
        super.layout()
        let transform = CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -bounds.width, y: 0.0)
        layer?.setAffineTransform(transform)
    }
    
    func setup() {
        framebufferOnly = false
        autoResizeDrawable = true
        layerContentsPlacement = .scaleProportionallyToFit
        preferredFramesPerSecond = 60
        layer?.isOpaque = false
    }

}


