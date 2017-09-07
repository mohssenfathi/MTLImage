//
//  CameraBase-iOS.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/7/17.
//

import Foundation
import AVFoundation

public
class CameraBase: NSObject {

    init(session: AVCaptureSession) {
        self.session = session
    }
    
    override init() {
        super.init()
        setupAVDevice()
    }
    
    /* Capture a still photo from the capture device. */
//    TODO: Add intermediate thumbnail captured photo callback
    public func takePhoto(_ completion: @escaping CaptureCallback) {
        
        guard let photoOutput = photoOutput else {
            completion(nil, nil, nil)
            return
        }
        
        currentCaptureCallback = completion
        
        let settings = AVCapturePhotoSettings()
        settings.isAutoStillImageStabilizationEnabled = isImageStabilizationEnabled
        settings.flashMode = flashMode
        //        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        //        let previewFormat = [
        //            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
        //            kCVPixelBufferWidthKey as String: 160,
        //            kCVPixelBufferHeightKey as String: 160
        //        ]
        //        settings.previewPhotoFormat = previewFormat
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    public func startRunning() { session.startRunning() }
    public func stopRunning()  { session.stopRunning() }
    
    public func flip() {
        mode = (mode == .front) ? .back : .front
    }
    
    public var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if let connection = dataOutput?.connection(with: AVMediaType.video) {
                connection.videoOrientation = orientation
            }
        }
    }
    
    public var mode: Mode = .back {
        didSet {
            session.apply { self.setupInputs() }
        }
    }
    
    public var preset: AVCaptureSession.Preset = .photo {
        didSet {
            session.apply {
                session.sessionPreset = preset
                setupInputs()
            }
        }
    }
    
    // MARK: - Properties
    
    // MARK: - Camera Properties
    //    TODO: Normalize these values between 0 - 1
    
    /* Flash: On, Off, and Auto */
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    public var isImageStabilizationEnabled: Bool = true
    
    /* Torch: On, Off, and Auto. Auto untested */
    public var torchMode: AVCaptureDevice.TorchMode = .off {
        didSet {
            applyCameraSetting { self.captureDevice.torchMode = self.torchMode }
        }
    }
    
    /* Flip: Front and Back supported */
    public var cameraPosition: AVCaptureDevice.Position = .front {
        didSet {
            mode = Mode.mode(for: cameraPosition)
        }
    }
    
    /* Zoom */
    public var maxZoom: Float { return Float(captureDevice.activeFormat.videoMaxZoomFactor) }
    public var zoom: Float = 0.0 {
        didSet {
            Tools.clamp(&zoom, low: 0, high: 1)
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
                self.captureDevice.setExposureModeCustom(duration: ed, iso: AVCaptureDevice.currentISO, completionHandler: nil)
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
                self.captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: value, completionHandler: nil)
            }
        }
    }
    
    /* Focus */
    public var focusMode: AVCaptureDevice.FocusMode = .autoFocus
    public func setFocusAuto() {
        applyCameraSetting {
            self.captureDevice.focusMode = .autoFocus
        }
    }
    public var lensPosition: Float = 0.0 {
        didSet {
            if captureDevice.isAdjustingFocus { return }
            applyCameraSetting {
                self.captureDevice.setFocusModeLocked(lensPosition: self.lensPosition, completionHandler: nil)
            }
        }
    }
    
    /* White Balance */
    var whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains!
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
                
                self.captureDevice.setWhiteBalanceModeLocked(with: self.whiteBalanceGains, completionHandler: nil)
            }
        }
    }
    
    
    // MARK: - Mode
    public enum Mode: Int {
        case back
        case front
        case dual
        case telephoto
        case depth
        
        func device() -> AVCaptureDevice? {
            
            var position: AVCaptureDevice.Position = .unspecified
            var deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
            let mediaType: AVMediaType = .video
            
            switch self {
            case .back:
                position = .back
            case .front:
                position = .front
            case .dual, .depth:
                position = .back
                deviceType = .builtInDuoCamera
            case .telephoto:
                position = .back
                deviceType = .builtInTelephotoCamera
            }
            
            let session = AVCaptureDevice.DiscoverySession(
                deviceTypes: [deviceType],
                mediaType: mediaType,
                position: position
            )
            
            return session.devices.first
        }
        
        var capturePosition: AVCaptureDevice.Position {
            switch self {
            case .back, .dual, .telephoto, .depth: return .back
            case .front: return .front
            }
        }
        
        static func mode(for position: AVCaptureDevice.Position) -> Mode {
            return position == .front ? .front : .back
        }
    }
    
    public typealias CaptureCallback = ((_ photo: UIImage?, _ metadata: PhotoMetadata?, _ error: Error?) -> ())
    
    // MARK: - Internal
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var photoOutput: AVCapturePhotoOutput?
    var dataOutput: AVCaptureVideoDataOutput?
    var dataOutputQueue: DispatchQueue = DispatchQueue(label: "VideoDataOutputQueue")
    var deviceInput: AVCaptureDeviceInput!
    fileprivate var currentCaptureCallback: CaptureCallback?
    
    // Depth
    private var depthDataOutput: AVCaptureOutput?
    var depthPixelBuffer: CVPixelBuffer?
    var depthContext: DepthContext = DepthContext(minDepth: 0, maxDepth: Float.greatestFiniteMagnitude)
    struct DepthContext {
        var minDepth: Float
        var maxDepth: Float
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraBase: AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let data = photo.fileDataRepresentation() else {
            handleTakenPhoto(photo: nil, metadata: nil, error: error)
            return
        }
        let metadata = try? PhotoMetadata(metadata: photo.metadata)
        handleTakenPhoto(photo: UIImage(data: data), metadata: metadata, error: error)
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let sampleBuffer = photoSampleBuffer,
            let jpeg = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                handleTakenPhoto(photo: nil, metadata: nil, error: error)
                return
        }
        
        handleTakenPhoto(photo: UIImage(data: jpeg), metadata: nil, error: error)
    }
    
    func handleTakenPhoto(photo: UIImage?, metadata: PhotoMetadata?, error: Error?) {
        guard let callback = currentCaptureCallback else { return }
        
        DispatchQueue.main.async {
            callback(photo, metadata, error)
            self.currentCaptureCallback = nil
        }
    }
    
    

}


// MARK: - Setup
extension CameraBase {
    
    func setupAVDevice() {

        session = AVCaptureSession()
        session.sessionPreset = preset
        
        session.beginConfiguration()
        setupInputs()
        setupOutputs()
        session.commitConfiguration()
    }
    
    func setupInputs() {
        
        if deviceInput != nil {
            session.removeInput(deviceInput)
        }
        
        captureDevice = mode.device()
//        captureDevice.configureForHighestFrameRate()
        assert(captureDevice != nil, "No Capture Devices Available")
        whiteBalanceGains = captureDevice.deviceWhiteBalanceGains
        
        deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        assert(deviceInput != nil, "No Camera Inputs Available")
        
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        dataOutput?.connection(with: .video)?.videoOrientation = .portrait
        photoOutput?.connection(with: .video)?.videoOrientation = .portrait
    }
    
    func setupOutputs() {
        
        // Data Output
        dataOutput = AVCaptureVideoDataOutput()
        if let dataOutput = dataOutput {
            dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCMPixelFormat_32BGRA)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            if session.canAddOutput(dataOutput) {
                session.addOutput(dataOutput)
            }
        }
        
        // Capture Photo Output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
        
        // Depth Data Output
        if #available(iOS 11.0, *), mode == .depth {
            depthDataOutput = AVCaptureDepthDataOutput()
            (depthDataOutput as! AVCaptureDepthDataOutput).setDelegate(self, callbackQueue: DispatchQueue(label: "DepthDataOutputQueue"))
            (depthDataOutput as! AVCaptureDepthDataOutput).alwaysDiscardsLateDepthData = true
            (depthDataOutput as! AVCaptureDepthDataOutput).isFilteringEnabled = true
            if session.canAddOutput(depthDataOutput!) {
                session.addOutput(depthDataOutput!)
            }
        }
        
        dataOutput?.connection(with: .video)?.videoOrientation = .portrait
        photoOutput?.connection(with: .video)?.videoOrientation = .portrait
    }
}

//MARK: -  Editing
extension CameraBase {
    
    /*  Locks camera, applies settings change, then unlocks.
     Returns success                                       */
    
    @discardableResult
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

extension CameraBase: AVCaptureVideoDataOutputSampleBufferDelegate { }

// MARK: - Depth
// MARK: AVCaptureDepthDataOutputDelegate
extension CameraBase: AVCaptureDepthDataOutputDelegate {
    
    @available(iOS 11.0, *)
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        
        guard mode == .depth else { return }
        
        guard let textureFormat = depthData.depthDataMap.mtlPixelFormat_Depth else { return }
        
        (depthContext.minDepth, depthContext.maxDepth) = minMax(from: depthData.depthDataMap, format: textureFormat)
        
        let depthData = depthData.applyingExifOrientation(CGImagePropertyOrientation.right).converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        depthPixelBuffer = depthData.depthDataMap
    }
    
    @available(iOS 11.0, *)
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
        
    }
    
}


extension AVCaptureSession {
    
    func apply(_ changes: (() -> ())) {
        beginConfiguration()
        changes()
        commitConfiguration()
    }
    
}
