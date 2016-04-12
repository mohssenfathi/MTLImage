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
protocol MTLViewDelegate {
    func mtlViewTouchesBegan(sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesMoved(sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesEnded(sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
}

public
class MTLView: UIView, MTLOutput {
    
    public var delegate: MTLViewDelegate?
    
    private var privateInput: MTLInput?
    var displayLink: CADisplayLink!
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var library: MTLLibrary!
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    lazy var commandQueue: MTLCommandQueue! = {
        return self.device.newCommandQueue()
    }()
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!
    var uniformsBuffer: MTLBuffer!
    var renderPassDescriptor: MTLRenderPassDescriptor!
    var semaphore = dispatch_semaphore_create(3)
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = NSUUID().UUIDString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    public var frameRate: Int = 60 {
        didSet {
            Tools.clamp(&frameRate, low: 0, high: 60)
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
        title = "MTLView"
        setupDevice()
        setupPipeline()
        setupBuffers()
    }
    
    override public func didMoveToSuperview() {
        if superview != nil {
            displayLink = CADisplayLink(target: self, selector: #selector(MTLView.update(_:)))
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
    
//    MARK: - Touch Events
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        delegate?.mtlViewTouchesBegan(self, touches: touches, event: event)
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        delegate?.mtlViewTouchesMoved(self, touches: touches, event: event)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        delegate?.mtlViewTouchesEnded(self, touches: touches, event: event)
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
        metalLayer.drawsAsynchronously = true
    }
    
    func setupPipeline() {
        library = context.library
        vertexFunction   = library.newFunctionWithName("vertex_main")
        fragmentFunction = library.newFunctionWithName("fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
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
            let imageRatio = Float(input!.texture!.width) / Float(input!.texture!.height)
            
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
        
        let width: Float = 0.99
        let kQuadTexCoords: [float2] = [
            float2(0.0, 0.0),
            float2(width, 0.0),
            float2(0.0, width),
            
            float2(width, 0.0),
            float2(0.0, width),
            float2(width, width) ]
        
        vertexBuffer   = device.newBufferWithBytes(kQuadVertices , length: kSzQuadVertices , options: .CPUCacheModeDefaultCache)
        texCoordBuffer = device.newBufferWithBytes(kQuadTexCoords, length: kSzQuadTexCoords, options: .CPUCacheModeDefaultCache)
    }
    
    func redraw() {
        if input?.texture == nil { return }
        
        runSynchronously {
            autoreleasepool {
                
//                dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)

                let drawable = self.metalLayer.nextDrawable()
                let texture = drawable?.texture
                
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = texture
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
                renderPassDescriptor.colorAttachments[0].storeAction = .Store
                renderPassDescriptor.colorAttachments[0].loadAction = .Clear
                
                let commandBuffer = self.commandQueue.commandBuffer()
                let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
                commandEncoder.setRenderPipelineState(self.pipeline)
                commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
                commandEncoder.setVertexBuffer(self.texCoordBuffer, offset: 0, atIndex: 1)
                commandEncoder.setFragmentTexture(self.input?.texture, atIndex: 0)
                commandEncoder.setFragmentBuffer(self.uniformsBuffer, offset: 0, atIndex: 1)
                commandEncoder.drawPrimitives(.Triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
                
                commandEncoder.endEncoding()
                
                commandBuffer.presentDrawable(drawable!)
                
//                commandBuffer.addCompletedHandler({ (commandBuffer) in
//                    dispatch_semaphore_signal(self.semaphore)
//                })
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
        }
    }
    
    
    //    MARK: - Queues
    
    func runSynchronously(block: (()->())) {
        dispatch_sync(context.processingQueue) {
            block()
        }
    }
    
    func runAsynchronously(block: (()->())) {
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        dispatch_async(context.processingQueue) {
            block()
//            dispatch_semaphore_signal(self.semaphore)
        }
        
    }
    
    
    var context: MTLContext! {
        get {
            if input?.context == nil {
                return MTLContext()
            }
            return input?.context
        }
    }
    
    //    MARK: - MTLOutput
    
    public var input: MTLInput? {
        get {
            return self.privateInput
        }
        set {
            privateInput = newValue
            
            if privateInput == nil {
                displayLink.paused = true
            } else {
                displayLink.paused = false
                setupBuffers()
            }
        }
    }
    
}
