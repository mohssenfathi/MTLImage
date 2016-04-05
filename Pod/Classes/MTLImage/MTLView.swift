//
//  MTLView.swift
//  Pods
//
//  Created by Mohssen Fathi on 3/25/16.
//
//

import UIKit
import MetalKit

public
class MTLView: UIView, MTLOutput {

    private var privateInput: MTLInput?
    
    var displayLink: CADisplayLink!
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var library: MTLLibrary!
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    
    var renderingQueue: dispatch_queue_t!
    var jobIndex: Int = 0
    
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!
    var uniformsBuffer: MTLBuffer!
    
    public var frameRate: Int = 60 {
        willSet {
            if      newValue > 60 { frameRate = 60 }
            else if newValue < 0  { frameRate = 0  }
            else                  { frameRate = newValue }
        }
        
        didSet {
            displayLink.frameInterval = 60/frameRate
        }
    }
    
    public override var contentMode: UIViewContentMode {
        didSet {
            setupBuffers()
        }
    }
    
    public override var bounds: CGRect {
        didSet { setupBuffers() }
    }
    
    public override var frame: CGRect {
        didSet { setupBuffers() }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        renderingQueue = dispatch_queue_create("Rendering", DISPATCH_QUEUE_SERIAL);
        setupDevice()
        setupPipeline()
        setupBuffers()
    }
    
    override public func didMoveToSuperview() {
        if superview != nil {
            displayLink = CADisplayLink(target: self, selector: "update:")
            displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        } else {
            displayLink.invalidate()
            displayLink = nil
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        if window != nil {
            let scale = window!.screen.nativeScale
            contentScaleFactor = scale
            metalLayer.frame = CGRect(origin: CGPointZero, size: bounds.size)
            metalLayer.drawableSize = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale)
        }
    }
    
    func update(displayLink: CADisplayLink) {
        self.redraw()
    }
    
    public func stopProcessing() {
        displayLink.paused = true
    }
    
    public func resumeProcessing() {
        displayLink.paused = false
    }
    
    override public class func layerClass() -> AnyClass {
        return CAMetalLayer.self
    }
    
    
//    func updateViewScale(scale: CGFloat) {
//        if window != nil {
//            let newScale = window!.screen.nativeScale * scale
//            let layerSize = bounds.size
//            
//            contentScaleFactor = newScale
//            metalLayer.frame = CGRect(origin: CGPointZero, size: layerSize)
//            metalLayer.drawableSize = CGSizeMake(layerSize.width * newScale, layerSize.height * newScale)
//            metalLayer.drawableSize = CGSizeMake(layerSize.width * newScale, layerSize.height * newScale)
//        }
//    }
    
    func setupDevice() {
        device = MTLCreateSystemDefaultDevice()
        metalLayer = layer as! CAMetalLayer
        metalLayer.device = device
        metalLayer.pixelFormat = MTLPixelFormat.BGRA8Unorm
    }
    
    func setupPipeline() {
        library = device.newDefaultLibrary()
        vertexFunction   = library.newFunctionWithName("vertex_main")
        fragmentFunction = library.newFunctionWithName("fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
        
        commandQueue = device.newCommandQueue()
    }
    
    func setupBuffers() {
        
        if device == nil { return }

        let kCntQuadTexCoords = 6;
        let kSzQuadTexCoords  = kCntQuadTexCoords * sizeof(float2);
        
        let kCntQuadVertices = kCntQuadTexCoords;
        let kSzQuadVertices  = kCntQuadVertices * sizeof(float4);
        
        var x: Float = 0.0, y: Float = 0.0
        if input != nil && input?.texture != nil {
            let viewSize  = bounds.size
            
            let viewRatio  = Float(viewSize.width / viewSize.height)
            let imageRatio = Float(input!.texture.width) / Float(input!.texture.height)
   
            if imageRatio > viewRatio {  // Image is wider than view
                y = (Float(viewSize.height) - (Float(viewSize.width) / imageRatio))/Float(viewSize.height)
            }
            else if viewRatio > imageRatio { // View is wider than image
                x = (Float(viewSize.width) - (Float(viewSize.height) * imageRatio))/Float(viewSize.width)
            }
        }
        
        let kQuadVertices: [float4] = [
            float4(-1.0 + x,  1.0 - y, 0.0, 1.0),
            float4( 1.0 - x,  1.0 - y, 0.0, 1.0),
            float4(-1.0 + x, -1.0 + y, 0.0, 1.0),
            
            float4( 1.0 - x,  1.0 - y, 0.0, 1.0),
            float4(-1.0 + x, -1.0 + y, 0.0, 1.0),
            float4( 1.0 - x, -1.0 + y, 0.0, 1.0) ]
        
        let kQuadTexCoords: [float2] = [
            float2(0.0, 0.0),
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            float2(1.0, 1.0) ]
        
        vertexBuffer   = device.newBufferWithBytes(kQuadVertices , length: kSzQuadVertices , options: .CPUCacheModeDefaultCache)
        texCoordBuffer = device.newBufferWithBytes(kQuadTexCoords, length: kSzQuadTexCoords, options: .CPUCacheModeDefaultCache)
    }

    func redraw() {
        let drawable = metalLayer.nextDrawable()
        let texture = drawable?.texture
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        
        let commandBuffer = commandQueue.commandBuffer()
        let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        commandEncoder.setVertexBuffer(texCoordBuffer, offset: 0, atIndex: 1)
        commandEncoder.setFragmentTexture(input?.texture, atIndex: 0)
        commandEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, atIndex: 1)
        commandEncoder.drawPrimitives(.Triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
     
        commandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
    }
    
    
    
//    MARK: - MTLOutput
    
    public var input: MTLInput? {
        get {
            return self.privateInput
        }
        set {
            privateInput = newValue
            setupBuffers()
        }
    }
    
}
