//
//  MTLCamera.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/12/16.
//
//

import UIKit
import AVFoundation

public
protocol MTLCameraDelegate {
    func mtlCameraFocusChanged(_ sender: MTLCamera, lensPosition: Float)
    func mtlCameraISOChanged(_ sender: MTLCamera, iso: Float)
    func mtlCameraExposureDurationChanged(_ sender: MTLCamera, exposureDuration: Float)
}

public
class MTLCamera: NSObject, MTLInput, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    
    /* For relaying changes in the 'Settings' section */
    public var delegate: MTLCameraDelegate?
    
    /* MTLFilters added to this group will filter the camera output */
    public var filterGroup = MTLFilterGroup()
    
    /* Capture a still photo from the capture device. */
//    TODO: Add intermediate thumbnail captured photo callback
    public func takePhoto(_ completion:@escaping ((_ photo: UIImage?, _ error: Error?) -> ())) {
        
        self.stillImageOutput.captureStillImageAsynchronously(from: self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)) { [weak self](sampleBuffer, error) in

            if error != nil {
                completion(nil, error)
                return
            }
            
            DispatchQueue(label: "CaptureQueue").async(execute: {
                
                guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else {
                    completion(nil, error)
                    return
                }
                
                // Get original image
                guard let image = UIImage(data: imageData) else {
                    completion(nil, error)
                    return
                }
                
//                let orientedImage = UIImage(cgImage: image.cgImage!, scale: 0.0, orientation: .up)
                
                // Filter original image
                let filterCopy = self?.filterGroup.copy() as! MTLFilterGroup
                guard let filteredImage = filterCopy.filter(image) else {
                    completion(nil, error)
                    return
                }
                
                completion(filteredImage, error)
                
            })
        
        }
        
    }
    
    // Gross, I know
    func fixOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up {
            return image
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -CGFloat(M_PI_2))
        default:
            break
        }
        
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let context = CGContext(data: nil,
                                      width: Int(image.size.width),
                                      height: Int(image.size.height),
                                      bitsPerComponent: image.cgImage!.bitsPerComponent,
                                      bytesPerRow: 0, space: image.cgImage!.colorSpace!,
                                      bitmapInfo: image.cgImage!.bitmapInfo.rawValue) else {
            return nil
        }
        
        context.concatenate(transform)
        
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
        default:
            context.draw(image.cgImage!, in: CGRect(origin: .zero, size: image.size))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let CGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: CGImage)
    }
    
    
    // MARK: Settings
    //    TODO: Normalize these values between 0 - 1
    
    /* Flash: On, Off, and Auto */
    public var flashMode: AVCaptureFlashMode = .auto {
        didSet {
            applyCameraSetting { self.captureDevice.flashMode = self.flashMode }
        }
    }
    
    /* Torch: On, Off, and Auto. Auto untested */
    public var torchMode: AVCaptureTorchMode = .off {
        didSet {
            applyCameraSetting { self.captureDevice.torchMode = self.torchMode }
        }
    }
    
    /* Flip: Front and Back supported */
    public var cameraPosition: AVCaptureDevicePosition = .front {
        didSet {
            capturePosition = cameraPosition
        }
    }
    
    /* Zoom */
    public var maxZoom: Float { return Float(captureDevice.activeFormat.videoMaxZoomFactor) }
    public var zoom: Float = 0.0 {
        didSet {
            applyCameraSetting {
                self.captureDevice.videoZoomFactor = CGFloat(self.zoom * 4.0 + 1.0)
            }
        }
    }
    
    /* Exposure */
    public func setExposureAuto() {
        applyCameraSetting {
            self.captureDevice.exposureMode = .autoExpose
        }
    }

    var minExposureDuration: Float = 0.004
    var maxExposureDuration: Float = 0.100 // 0.250
    public var exposureDuration: Float = 0.01 {
        didSet {
            if captureDevice.isAdjustingExposure { return }
            applyCameraSetting {
                let seconds = Tools.convert(self.exposureDuration, oldMin: 0, oldMax: 1,
                                            newMin: self.minExposureDuration, newMax: self.maxExposureDuration)
                let ed = CMTime(seconds: Double(seconds), preferredTimescale: 1000 * 1000)
                self.captureDevice.setExposureModeCustomWithDuration(ed, iso: AVCaptureISOCurrent, completionHandler: nil)
            }
        }
    }
    
    /* ISO */
    public func setISOAuto() {
        applyCameraSetting {
            self.captureDevice.exposureMode = .autoExpose
        }
    }
 
    
    let minIso: Float  = 29.000
    let maxIso: Float  = 1200.0
    public var iso: Float! {
        didSet {
            if captureDevice.isAdjustingExposure { return }
            applyCameraSetting {
                let value = Tools.convert(self.iso, oldMin: 0, oldMax: 1, newMin: self.minIso, newMax: self.maxIso)
                self.captureDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, iso: value, completionHandler: nil)
            }
        }
    }
    
    /* Focus */
    public var focusMode: AVCaptureFocusMode = .autoFocus
    public func setFocusAuto() {
        applyCameraSetting {
            self.captureDevice.focusMode = .autoFocus
        }
    }
    public var lensPosition: Float = 0.0 {
        didSet {
            if captureDevice.isAdjustingFocus { return }
            applyCameraSetting {
                self.captureDevice.setFocusModeLockedWithLensPosition(self.lensPosition, completionHandler: nil)
            }
        }
    }
    
    /* White Balance */
    var whiteBalanceGains: AVCaptureWhiteBalanceGains!
    public var tint: UIColor! {
        didSet {
            if captureDevice.isAdjustingWhiteBalance { return }
            applyCameraSetting {

                if let components = self.tint.components() {
                    let max = self.captureDevice.maxWhiteBalanceGain
                    self.whiteBalanceGains.redGain   = Tools.convert(Float(components.red)  , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                    self.whiteBalanceGains.greenGain = Tools.convert(Float(components.green), oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                    self.whiteBalanceGains.blueGain  = Tools.convert(Float(components.blue) , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                }
                
                self.captureDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(self.whiteBalanceGains, completionHandler: nil)
            }
        }
    }
    
    
    /*  Init  */
    
    public override init() {
        super.init()
        
        self.title = "MTLCamera"
        context.source = self
        
        setupAVDevice()
        setupPipeline()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    let cameraContext: UnsafeMutableRawPointer? = nil
    private func addObservers() {
//        UIDevice.current().beginGeneratingDeviceOrientationNotifications()
//        NotificationCenter.default().addObserver(self, selector: #selector(MTLCamera.orientationDidChange(notification:)),
//                                                 name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        captureDevice.addObserver(self, forKeyPath: "exposureDuration", options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "lensPosition"    , options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "ISO"             , options: NSKeyValueObservingOptions.new, context: cameraContext)
    }
    
    private func removeObservers() {
//        UIDevice.current().endGeneratingDeviceOrientationNotifications()
//        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        captureDevice.removeObserver(self, forKeyPath: "exposureDuration", context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "lensPosition"    , context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "ISO"             , context: cameraContext)
    }
    
    func orientationDidChange(_ notification: Notification) {
//        if let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo) {
//            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current().orientation.rawValue)!
//        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
        if captureDevice.position == .front { return }

        if context == cameraContext {
            
            guard let keyPath = keyPath else { return }
            
            switch keyPath {
            case "exposureDuration":
                let duration = Tools.convert(Float(captureDevice.exposureDuration.seconds),
                                             oldMin: minExposureDuration, oldMax: maxExposureDuration,
                                             newMin: 0, newMax: 1)
                delegate?.mtlCameraExposureDurationChanged(self, exposureDuration: duration)
                break
                
            case "lensPosition":
                delegate?.mtlCameraFocusChanged(self, lensPosition: captureDevice.lensPosition)
                break
                
            case "ISO":
                let iso = Tools.convert(captureDevice.iso, oldMin: minIso, oldMax: maxIso, newMin: 0, newMax: 1)
                delegate?.mtlCameraISOChanged(self, iso: iso)
                break
                
            default: break
            }
            
        }
    }
    
    public func startRunning() {
        session.startRunning()
    }
    
    public func stopRunning() {
        session.stopRunning()
    }
    
    public var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = orientation
            }
        }
    }
    
    public var capturePosition: AVCaptureDevicePosition = .back {
        didSet {
            if captureDevice.position == capturePosition { return }
            if session == nil { return }
            
            session.beginConfiguration()
            
            session.removeInput(deviceInput)  // maybe check if has input first
            
            for device: AVCaptureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice] {
                if device.position == capturePosition {
                    captureDevice = device 
                    break
                }
            }
            
            if captureDevice == nil {
                captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            }
            
            try! deviceInput = AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo)
            connection?.videoOrientation = .portrait
            connection?.isVideoMirrored = (capturePosition == .front)
            
            session.commitConfiguration()
        }
    }
    
    public func flipCamera() {
        capturePosition = (capturePosition == .front) ? .back : .front
    }
    
    func setupAVDevice() {
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        for device: AVCaptureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice] {
            if device.position == capturePosition {
                captureDevice = device 
                break
            }
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        try! deviceInput = AVCaptureDeviceInput(device: captureDevice)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        // Sample Buffer Output
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCMPixelFormat_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        }
        
        // Still Image Capture
        stillImageOutput = AVCaptureStillImageOutput()
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        
        let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.isEnabled = true
        connection?.videoOrientation = .portrait
        
        session.commitConfiguration()
        
        // Initial Values
        whiteBalanceGains = captureDevice.deviceWhiteBalanceGains
        stillImageOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.makeFunction(name: "camera")
        do {
            pipeline = try context.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    
//    MARK: - SampleBuffer Delegate
    
//    let semaphore = DispatchSemaphore(value: 1)
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
//        semaphore.wait(timeout: .distantFuture)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            semaphore.wait(timeout: .distantFuture)
            return
        }
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer);
        let height = CVPixelBufferGetHeight(pixelBuffer);
        
        guard let textureCache = textureCache else {
//            semaphore.signal()
            return
        }
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvMetalTexture)
        
        guard let cvMetalTex = cvMetalTexture else { return }
        internalTexture = CVMetalTextureGetTexture(cvMetalTex)
        
        needsUpdate = true
    }
        
    public func didFinishProcessing() {
        context.semaphore.signal()
    }
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = UUID().uuidString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    public var processingSize: CGSize! {
        didSet {
            context.processingSize = processingSize
        }
    }
    
    private var privateNeedsUpdate = true
    public var needsUpdate: Bool {
        set {
            privateNeedsUpdate = newValue
            for target in targets {
                if var inp = target as? MTLInput {
                    inp.needsUpdate = newValue
                }
            }
        }
        get {
            return privateNeedsUpdate
        }
    }
    
    public func setProcessingSize(_ processingSize: CGSize, respectAspectRatio: Bool) {
        let size = processingSize
        if respectAspectRatio == true {
            if size.width > size.height {
//                size.height = size.width / (image.size.width / image.size.height)
            }
            else {
//                size.width = size.height * (image.size.width / image.size.height)
            }
        }
        
        self.processingSize = size
    }
    
    func chainLength() -> Int {
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
        return c
    }
    
    func length(_ target: MTLOutput) -> Int {
        var c = 1
        
        if let input = target as? MTLInput {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }
        
        return c
    }
    
    
    //    MARK: - Processing
    
    public func process() {
        
        if videoTexture == nil { return }
        if internalTexture == nil || internalTexture!.width != videoTexture.width || internalTexture!.height != videoTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: videoTexture.pixelFormat, width:videoTexture.width, height: videoTexture.height, mipmapped: false)
            internalTexture = context.device?.makeTexture(descriptor: textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(16, 16, 1)
        let threadgroups = MTLSizeMake(videoTexture.width / threadgroupCounts.width,
                                       videoTexture.height / threadgroupCounts.height, 1)
        
        let commandBuffer = context.commandQueue.makeCommandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.needsUpdate = false
        }
        
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        
        commandEncoder.setTexture(videoTexture, at: 0)
        commandEncoder.setTexture(internalTexture, at: 1)
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    
    //    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            // Enable if you want to do some processing before passing on the texture (currently not working)
//            if needsUpdate == true { process() }
            return internalTexture
        }
    }
    
    public var context: MTLContext {
        get {
            return internalContext
        }
    }
    
    public var device: MTLDevice {
        get {
            return context.device
        }
    }
    
    public var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    
    public func addTarget(_ target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        t.input = self
        startRunning()
    }
    
    public func removeTarget(_ target: MTLOutput) {
        var t = target
        t.input = nil
        //      TODO:   remove from internalTargets
    }
    
    public func removeAllTargets() {
        //        for var target in internalTargets {
        //            target.input = nil
        //        }
        internalTargets.removeAll()
        stopRunning()
    }
    
    
//    MARK: - Internal
    private var internalTargets = [MTLOutput]()
    private var internalTexture: MTLTexture!
    private var videoTexture: MTLTexture!
    var internalContext: MTLContext = MTLContext()
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var stillImageOutput: AVCaptureStillImageOutput!
    var dataOutput: AVCaptureVideoDataOutput!
    var dataOutputQueue: DispatchQueue!
    var deviceInput: AVCaptureDeviceInput!
    var textureCache: CVMetalTextureCache?

}


//  Editing
extension MTLCamera {

    /*  Locks camera, applies settings change, then unlocks.
        Returns success                                       */
    
    func applyCameraSetting( _ settings: (() -> ()) ) -> Bool {
        if !lock() {  return false }

        settings()
        
        unlock()
        return true
    }
    
    
    func lock() -> Bool {
        do    { try captureDevice.lockForConfiguration() }
        catch { return false }
        return true
    }

    func unlock() {
        captureDevice.unlockForConfiguration()
        
    }

}


extension UIColor {
    
    func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        
        var red  : CGFloat = 0
        var green: CGFloat = 0
        var blue : CGFloat = 0
        var alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        } else {
            return nil
        }
    }
}
