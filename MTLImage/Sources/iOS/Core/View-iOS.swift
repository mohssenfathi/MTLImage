//
//  View.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/13/16.
//
//

import UIKit
import MetalKit

public
class View: UIView, Output {
    
    private var renderer = Renderer()
    public var renderView: RendererBase {
        get {
            return renderer
        }
        set {
            if let v = newValue as? Renderer { renderer = v }
        }
    }
    let scrollView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
        isPaused = false
        
        scrollView.frame = bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
        
        renderView.hostView = self
        renderView.frame = bounds
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(renderView)
        
        contentMode = .scaleAspectFit
    }
    
    func reload() {
        
        renderView.device = input?.context.device
        renderView.input = input
        renderView.reload()
        isPaused = false
        
        if let input = input {
            renderView.enableSetNeedsDisplay = !input.continuousUpdate
            renderView.isPaused              = !input.continuousUpdate
        }
        
        renderView.draw()
    }
    
    public override var contentMode: UIViewContentMode {
        didSet {
            renderView.contentMode = contentMode
        }
    }
    
    public override func setNeedsDisplay() {
        DispatchQueue.main.async {
            super.setNeedsDisplay()
            self.renderView.setNeedsDisplay()
        }
    }
    
    
    // MARK: - Properties
    public var input: Input? {
        didSet { reload() }
    }
    
    public var title: String  = "View"
    public var id: String = UUID().uuidString
    
    public var isZoomEnabled = true {
        didSet {
            if !isZoomEnabled {
                scrollView.setZoomScale(1.0, animated: false)
            }
        }
    }
    
    public var preferredFramesPerSecond: Int = 60 {
        didSet {
            renderView.preferredFramesPerSecond = preferredFramesPerSecond
        }
    }
    
    public var imageRect: CGRect {
        return Tools.imageFrame(renderView.drawableSize, rect: renderView.frame)
    }
    
    public var isPaused: Bool {
        set { renderView.isPaused = newValue }
        get { return renderView.isPaused     }
    }
    
    public var isEnabled: Bool = true

    public var snapshot: UIImage? {
        return input?.texture?.image
    }
}

extension View: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isZoomEnabled ? renderView : nil
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let imageSize = renderView.drawableSize
        let imageFrame = Tools.imageFrame(imageSize, rect: renderView.frame)
        
        var y = imageFrame.origin.y - (frame.height/2 - imageFrame.height/2)
        var x = imageFrame.origin.x - (frame.width/2 - imageFrame.width/2)
        y = min(imageFrame.origin.y, y)
        x = min(imageFrame.origin.x, x)
        
        scrollView.contentInset = UIEdgeInsetsMake(-y, -x, -y, -x);
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        if let texture = input?.texture {
            renderView.drawableSize = CGSize(width: texture.width, height: texture.height) * scale
        }
        
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isZooming { return }
    }
}



public
class Renderer: RendererBase {
    
    override func render(encoder: MTLRenderCommandEncoder) {
        renderImage(encoder: encoder)
    }
    
    func renderImage(encoder: MTLRenderCommandEncoder) {
        
        guard let texture = input?.texture else { return }
        
        if texture.cgSize != drawableSize {
            drawableSize = texture.cgSize
            return
        }
        
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
    }
    
}


// MARK: - Renderer Base
public
class RendererBase: MTKView, MTKViewDelegate {
    
    var input: Input?
    weak var hostView: View!
    public var library: MTLLibrary?
    
    let renderSemaphore = DispatchSemaphore(value: 3)
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    
    var textureSize: CGSize {
        return input?.texture?.cgSize ?? bounds.size
    }
    
    var renderTransform: CGAffineTransform = .identity {
        didSet { updateTransform() }
    }
    
    private let fpsCounter = FPSCounter()
    public var logFPS: Bool = false {
        didSet {
            logFPS ? fpsCounter.startTracking() : fpsCounter.stopTracking()
        }
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: nil)
        loadView()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        loadView()
    }
    
    func loadView() {
        
        delegate = self
        clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        backgroundColor = .clear
        framebufferOnly = false
        autoResizeDrawable = false
        contentMode = .scaleAspectFit
        
        fpsCounter.delegate = self
        if logFPS { fpsCounter.startTracking() }
    }
    
    func reload() {
        
        guard let library = input?.context.library, let device = device else { return }
        
        vertexFunction   = library.makeFunction(name: "vertex_main")
        fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    func updateTransform() {
        
//        let vertexData = imagePlaneVertexBuffer.contents().assumingMemoryBound(to: Float.self)
//        for index in 0...3 {
//            let textureCoordIndex = 4 * index + 2
//            let textureCoord = CGPoint(x: CGFloat(imagePlaneVertexData[textureCoordIndex]), y: CGFloat(imagePlaneVertexData[textureCoordIndex + 1]))
//            let transformedCoord = textureCoord.applying(renderTransform)
//            vertexData[textureCoordIndex] = Float(transformedCoord.x)
//            vertexData[textureCoordIndex + 1] = Float(transformedCoord.y)
//        }
        
    }
    
    func notifyOtherTargets() {
        for var destination in (hostView.source?.destinations ?? []) {
            if destination.id != hostView.id {
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
    
    public func draw(in view: MTKView) {

        // Causing issues
//        guard !view.isPaused else { return }
        
        notifyOtherTargets()
        input?.processIfNeeded()
        
//        if drawableSize != textureSize {
//            drawableSize = textureSize
//            return
//        }
        
        guard let commandQueue = input?.context.commandQueue,
            let drawable = view.currentDrawable else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        commandBuffer.addCompletedHandler({ _ in
            self.renderSemaphore.signal()
        })
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {

            renderSemaphore.wait()
            render(encoder: renderEncoder)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        // For subclassing
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
}

extension RendererBase: FPSCounterDelegate {
    public func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        if logFPS { print("\(fps) FPS") }
    }
}
