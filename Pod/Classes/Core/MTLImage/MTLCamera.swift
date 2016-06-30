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
    func mtlCameraFocusChanged(sender: MTLCamera, lensPosition: Float)
    func mtlCameraISOChanged(sender: MTLCamera, iso: Float)
    func mtlCameraExposureDurationChanged(sender: MTLCamera, exposureDuration: CMTime)
}

public
class MTLCamera: NSObject, MTLInput, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    
    /* For relaying changes in the 'Settings' section */
    public var delegate: MTLCameraDelegate?
    
    /* MTLFilters added to this group will filter the camera output */
    public var filterGroup = MTLFilterGroup()
    
    /* Capture a still photo from the capture device. TODO: Add intermediate thumbnail captured photo callback */
    public func takePhoto(completion:((photo: UIImage?, error: NSError?) -> ())) {
        
        self.stillImageOutput.captureStillImageAsynchronously(from: self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)) { (sampleBuffer, error) in
            if error != nil {
                completion(photo: nil, error: error)
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            let image = UIImage(data: imageData!)
            completion(photo: image, error: error)
        }
        
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
    public var zoom: Float = 1.0 {
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
    private var minExposureDuration: CMTime { return captureDevice.activeFormat.minExposureDuration }
    private var maxExposureDuration: CMTime { return captureDevice.activeFormat.maxExposureDuration }
    public var exposureDuration: CMTime! {
        didSet {
            if captureDevice.isAdjustingExposure { return }
            applyCameraSetting {
                let seconds = Tools.convert(self.exposureDuration.seconds, oldMin: 0, oldMax: 1,
                                            newMin: self.minExposureDuration.seconds, newMax: self.maxExposureDuration.seconds)
                let ed = CMTime(seconds: seconds, preferredTimescale: self.exposureDuration.timescale)
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
    private var minISO: Float { return captureDevice.activeFormat.minISO }
    private var maxISO: Float { return captureDevice.activeFormat.maxISO }
    public var iso: Float! {
        didSet {
            if captureDevice.isAdjustingExposure { return }
            applyCameraSetting {
                let value = Tools.convert(self.iso, oldMin: 0, oldMax: 1, newMin: self.minISO, newMax: self.maxISO)
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
        setupAVDevice()
        setupPipeline()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    let cameraContext: UnsafeMutablePointer<Void>? = nil
    private func addObservers() {
        captureDevice.addObserver(self, forKeyPath: "exposureDuration", options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "lensPosition"    , options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "ISO"             , options: NSKeyValueObservingOptions.new, context: cameraContext)
    }
    
    private func removeObservers() {
        captureDevice.removeObserver(self, forKeyPath: "exposureDuration", context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "lensPosition"    , context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "ISO"             , context: cameraContext)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        if captureDevice.position == .front { return }

        if context == cameraContext {
            
            guard let keyPath = keyPath else { return }
            
            switch keyPath {
            case "exposureDuration":
                delegate?.mtlCameraExposureDurationChanged(sender: self, exposureDuration: captureDevice.exposureDuration)
                break
            case "lensPosition":
                delegate?.mtlCameraFocusChanged(sender: self, lensPosition: captureDevice.lensPosition)
                break
            case "ISO":
                delegate?.mtlCameraISOChanged(sender: self, iso: captureDevice.iso)
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
            
            // Set flag later to mirror preview when in .Front
            
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
        dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: DispatchQueueAttributes.serial)
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
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.newFunction(withName: "camera")
        do {
            pipeline = try context.device.newComputePipelineState(with: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    
//    MARK: - SampleBuffer Delegate
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var textureRef : Unmanaged<CVMetalTexture>?
        let width = CVPixelBufferGetWidth(pixelBuffer!);
        let height = CVPixelBufferGetHeight(pixelBuffer!);
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!.takeUnretainedValue(), pixelBuffer!, nil, .bgra8Unorm, width, height, 0, &textureRef);
        internalTexture = CVMetalTextureGetTexture((textureRef?.takeUnretainedValue())!)
        textureRef?.release()
        needsUpdate = true
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
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(with: videoTexture.pixelFormat, width:videoTexture.width, height: videoTexture.height, mipmapped: false)
            internalTexture = context.device?.newTexture(with: textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(16, 16, 1)
        let threadgroups = MTLSizeMake(videoTexture.width / threadgroupCounts.width,
                                       videoTexture.height / threadgroupCounts.height, 1)
        
        let commandBuffer = context.commandQueue.commandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.needsUpdate = false
        }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
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
    var textureCache: Unmanaged<CVMetalTextureCache>?

}


//  Editing
extension MTLCamera {

    /*  Locks camera, applies settings change, then unlocks.
        Returns success                                       */
    
    func applyCameraSetting( settings: (() -> ()) ) -> Bool {
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
