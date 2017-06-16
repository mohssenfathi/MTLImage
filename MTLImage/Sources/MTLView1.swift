//
//  MTLView.swift
//  Pods
//
//  Created by Mohssen Fathi on 3/25/16.
//
//

import UIKit
import Metal
import MetalKit

public
protocol MTLViewDelegate1 {
    func mtlViewTouchesBegan(_ sender: MTLView1, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesMoved(_ sender: MTLView1, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesEnded(_ sender: MTLView1, touches: Set<UITouch>, event: UIEvent?)
}

public
class MTLView1: UIView, Output, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    
    public var identifier: String = UUID().uuidString
    
    public var delegate: MTLViewDelegate?
    public var isZoomEnabled: Bool = true {
        didSet {
            scrollView.isScrollEnabled = isZoomEnabled
        }
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
        context.output = self
        
        setupPipeline()
        updateBuffers()
        setupView()
    }
    
    //    MARK: - Gesture Recognizers
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //    MARK: - Display Link
    @objc func update(_ displayLink: CADisplayLink) {
        
        guard let input = input else { return }
        
        var shouldUpdate = input.needsUpdate
        
        if needsUpdateBuffers {
            self.updateBuffers()
            self.updateMetalLayerLayout()
            shouldUpdate = true
        }
        
        //        if updateMetalLayer && self.window != nil {
        //            self.updateMetalLayerLayout()
        //        }
        
        if shouldUpdate {
            redraw()
        }
    }
    
    public func stopProcessing() {
        displayLink.isPaused = true
    }
    
    public func resumeProcessing() {
        displayLink.isPaused = false
    }
    
    
    //    MARK: - View Layout
    override public func didMoveToSuperview() {
        if superview != nil {
            displayLink = CADisplayLink(target: self, selector: #selector(MTLView1.update(_:)))
            displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        } else {
            displayLink.invalidate()
        }
    }
    
    public func layoutView() {
        updateBuffers()
    }
    
    func setupView() {
        
        contentView = MetalLayerView(frame: bounds)
        contentView.backgroundColor = UIColor.clear
        contentMode = .scaleAspectFit
        contentView.parentView = self
        
        scrollView = UIScrollView(frame: bounds)
        scrollView.backgroundColor = UIColor.clear
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 100.0
        scrollView.delegate = self
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        scrollView.addSubview(contentView)
        addSubview(scrollView)
        
        metalLayer = contentView.layer as! CAMetalLayer
        metalLayer.device = device
        metalLayer.pixelFormat = MTLPixelFormat.bgra8Unorm
        metalLayer.drawsAsynchronously = true
        metalLayer.frame = bounds
        
        updateMetalLayer = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        metalLayer.frame = bounds
        updateMetalLayer = true
    }
    
    func setupPipeline() {
        device = context.device
        library = context.library
        vertexFunction   = library.makeFunction(name: "vertex_main")
        fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    func updateMetalLayerLayout() {
        
//        guard window != nil else { return }
        
//        let scale = window!.screen.nativeScale
//        contentScaleFactor = scale
//        metalLayer.drawableSize = metalLayer.frame.size * UIScreen.main.nativeScale
//        
//        self.updateMetalLayer = false
    }
    
    
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
    
    private var needsUpdateBuffers = true
    func updateBuffers() {
        
        if device == nil { return }
        
        let ins = insets(contentMode)
        let x = ins.x
        let y = ins.y
        
        kQuadVertices = [ float4(-1.0 + x,  1.0 - y, 0.0, 1.0),
                          float4( 1.0 - x,  1.0 - y, 0.0, 1.0),
                          float4(-1.0 + x, -1.0 + y, 0.0, 1.0),
                          
                          float4( 1.0 - x,  1.0 - y, 0.0, 1.0),
                          float4(-1.0 + x, -1.0 + y, 0.0, 1.0),
                          float4( 1.0 - x, -1.0 + y, 0.0, 1.0) ]
        
        vertexBuffer = device.makeBuffer(bytes: kQuadVertices , length: kSzQuadVertices , options: MTLResourceOptions())
        if texCoordBuffer == nil {
            texCoordBuffer = device.makeBuffer(bytes: kQuadTexCoords, length: kSzQuadTexCoords, options: MTLResourceOptions())
        }
        
        self.needsUpdateBuffers = false
    }
    
    func insets(_ contentMode: UIViewContentMode) -> (x: Float, y: Float) {
        
        guard let inputTexture = input?.texture else { return (0,0) }
        
        let viewSize   = bounds.size
        let viewRatio  = viewSize.width / viewSize.height
        let imageRatio = CGFloat(inputTexture.width) / CGFloat(inputTexture.height)
        
        var x: Float = 0.0, y: Float = 0.0
        
        if contentMode == .scaleAspectFit {
            if imageRatio > viewRatio {  // Image is wider than view
                y = Float((viewSize.height - (viewSize.width / imageRatio)) / viewSize.height)
            }
            else if viewRatio > imageRatio { // View is wider than image
                x = Float((viewSize.width - (viewSize.height) * imageRatio) / viewSize.width)
            }
        }
        else if contentMode == .scaleAspectFill {
            if imageRatio > viewRatio {
                y = 0
                x = Float((viewSize.width - (viewSize.height) * imageRatio) / viewSize.width)
            }
            else if viewRatio > imageRatio {
                y = Float((viewSize.height - (viewSize.width) / imageRatio) / viewSize.height)
                x = 0
            }
        }
        
        return (x, y)
    }
    
    private var currentDrawable: CAMetalDrawable?
    var drawable: CAMetalDrawable? {
        if metalLayer.drawableSize == CGSize.zero {
            metalLayer.drawableSize = bounds.size * UIScreen.main.scale
        }
        if currentDrawable == nil {
            currentDrawable = metalLayer.nextDrawable()
        }
        return currentDrawable
    }
    
    
    func redraw() {
        
        context.semaphore.wait()
        
        context.processingQueue.async {
            
            guard let tex = self.input?.texture else {
                self.context.semaphore.signal()
                return
            }
            
            autoreleasepool {
                
                guard let drawable = self.drawable else { return }
                let texture = drawable.texture
                
                self.renderPassDescriptor.colorAttachments[0].texture = texture
                
                let commandBuffer = self.commandQueue.makeCommandBuffer()
                commandBuffer.label = "MTLView Buffer"
                
                let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor)
                commandEncoder.setRenderPipelineState(self.pipeline)
                commandEncoder.setVertexBuffer(self.vertexBuffer  , offset: 0, index: 0)
                commandEncoder.setVertexBuffer(self.texCoordBuffer, offset: 0, index: 1)
                commandEncoder.setFragmentTexture(tex, index: 0)
                
                commandEncoder.drawPrimitives(type: .triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
                commandEncoder.endEncoding()
                
                commandBuffer.addCompletedHandler({ (commandBuffer) in
                    self.currentDrawable = nil
                    self.context.semaphore.signal()
                    //                                self.context.source?.didFinishProcessing()
                })
                
                commandBuffer.present(drawable)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }   
        }
        
    }
    
    
    //    MARK: - UIScrollView Delegate
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isZoomEnabled ? contentView : nil
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        guard let tex = self.input?.texture else { return }
        
        let imageSize = CGSize(width: tex.width, height: tex.height)
        let imageFrame = Tools.imageFrame(imageSize, rect: self.contentView.frame)
        
        var y = imageFrame.origin.y - (frame.height/2 - imageFrame.height/2)
        var x = imageFrame.origin.x - (frame.width/2 - imageFrame.width/2)
        y = min(imageFrame.origin.y, y)
        x = min(imageFrame.origin.x, x)
        
        scrollView.contentInset = UIEdgeInsetsMake(-y, -x, -y, -x);
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        guard let viewSize = view?.frame.size else { return }
        
        //        let maxSize = FiltersManager.sharedManager.maxProcessingSize
        let minSize = bounds.size * UIScreen.main.scale
        let ratio = viewSize.width / viewSize.height
        
        //        if (viewSize.width > maxSize.width || viewSize.height > maxSize.height) {
        //            mtlView.processingSize = CGSize(width: maxSize.width, height: maxSize.width / ratio)
        //        }
        if (viewSize.width < minSize.width || viewSize.height < minSize.height) {
            metalLayer.drawableSize = CGSize(width: minSize.width, height: minSize.width / ratio)
        }
        else {
            metalLayer.drawableSize = viewSize
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isZooming { return }
    }
    
    func currentCropRegion(_ scrollView: UIScrollView) -> CGRect {
        
        var x = scrollView.contentOffset.x / scrollView.contentSize.width
        var y = scrollView.contentOffset.y / scrollView.contentSize.height
        var width  = scrollView.frame.size.width / scrollView.contentSize.width
        var height = scrollView.frame.size.height / scrollView.contentSize.height
        
        Tools.clamp(&x     , low: 0, high: 1)
        Tools.clamp(&y     , low: 0, high: 1)
        Tools.clamp(&width , low: 0, high: 1.0 - x)
        Tools.clamp(&height, low: 0, high: 1.0 - y)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    //    MARK: - Queues
    func runSynchronously(_ block: (()->())) {
        context.processingQueue.sync {
            block()
        }
    }
    
    func runAsynchronously(_ block: @escaping (()->())) {
        DispatchQueue.global(qos: .userInitiated).async {
            block()
        }
    }
    
    
    //    MARK: - MTLOutput
    public var input: Input? {
        get {
            return self.privateInput
        }
        set {
            privateInput = newValue
            
            if privateInput == nil {
                displayLink.isPaused = true
            } else {
                displayLink.isPaused = false
                needsUpdateBuffers = true
            }
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
    
    
    //    MARK: - Internal
    private var scrollView: UIScrollView!
    private var contentView: MetalLayerView!
    private var cropFilter = Crop()
    private var privateInput: Input?
    var displayLink: CADisplayLink!
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var library: MTLLibrary!
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!
    
    lazy var commandQueue: MTLCommandQueue! = {
        return self.device.makeCommandQueue()
    }()
    
    private var updateMetalLayer = true
    
    //    private var renderSemaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
    lazy var renderPassDescriptor: MTLRenderPassDescriptor = {
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].clearColor = self.mtlClearColor
        rpd.colorAttachments[0].storeAction = .store
        rpd.colorAttachments[0].loadAction = .clear
        return rpd
    }()
    

    //    MARK: - Properties
    
    private var mtlClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
    public var clearColor: UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0) {
        didSet {
            if      clearColor == UIColor.white { mtlClearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0) }
            else if clearColor == UIColor.black { mtlClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0) }
            else {
                let components = clearColor.cgColor.components
                mtlClearColor = MTLClearColorMake(Double((components?[0])!), Double((components?[1])!), Double((components?[2])!), Double((components?[3])!))
            }
        }
    }
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    
    public var frameRate: Int = 60 {
        didSet {
            Tools.clamp(&frameRate, low: 0, high: 60)
            
            #if os(tvOS)
                if #available(tvOS 10.0, *) {
                    displayLink.preferredFramesPerSecond = frameRate
                } else {
                    
                }
            #else
//                displayLink.frameInterval = 60 / frameRate
            #endif

        }
    }
    
    public override var contentMode: UIViewContentMode {
        didSet {
            needsUpdateBuffers = true
        }
    }
    
    public override var bounds: CGRect {
        didSet { needsUpdateBuffers = true }
    }
    
    public override var frame: CGRect {
        didSet { needsUpdateBuffers = true }
    }
    
    public var processingSize: CGSize! {
        didSet {
            if processingSize == CGSize.zero { return }
            metalLayer.drawableSize = processingSize
        }
    }
}


class MetalLayerView: UIView {
    
    var parentView: MTLView1?
    
    internal override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scale = window?.screen.scale ?? UIScreen.main.nativeScale
        (layer as! CAMetalLayer).drawableSize = bounds.size * scale
    }
   
    /*
    //    MARK: - Touch Events
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let mtlView = parentView {
            mtlView.delegate?.mtlViewTouchesBegan(mtlView, touches: touches, event: event)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if let mtlView = parentView {
            mtlView.delegate?.mtlViewTouchesMoved(mtlView, touches: touches, event: event)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let mtlView = parentView {
            mtlView.delegate?.mtlViewTouchesEnded(mtlView, touches: touches, event: event)
        }
    }
 */
}

func *(left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}
