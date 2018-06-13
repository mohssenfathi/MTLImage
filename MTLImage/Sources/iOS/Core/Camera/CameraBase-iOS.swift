//
//  CameraBase-iOS.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/7/17.
//

import Foundation
import AVFoundation
import Photos

@objc public
class CameraBase: NSObject {

    init(session: AVCaptureSession) {
        self.session = session
        self.photoOutput = AVCapturePhotoOutput()
        self.dataOutput = AVCaptureVideoDataOutput()
    }
    
    override init() {
        self.session = AVCaptureSession()
        self.photoOutput = AVCapturePhotoOutput()
        self.dataOutput = AVCaptureVideoDataOutput()
        
        super.init()
        
        setupAVDevice()
    }
    
    public var isLivePhotoEnabled: Bool {
        get {
            guard photoOutput.isLivePhotoCaptureSupported,
                photoOutput.isLivePhotoCaptureEnabled,
                !photoOutput.isLivePhotoCaptureSuspended else {
                return false
            }
            return true
        }
        set {
            guard photoOutput.isLivePhotoCaptureSupported else {
                return
            }
            
            if newValue == true, photoOutput.isLivePhotoCaptureEnabled == false {
                photoOutput.isLivePhotoCaptureEnabled = true
            }
            
            photoOutput.isLivePhotoCaptureSuspended = !newValue
        }
    }
    
    public var isDepthDataEnabled: Bool = false {
        didSet {
            if #available(iOS 11.0, *) {
                if isDepthDataEnabled == true,
                    photoOutput.isDepthDataDeliverySupported {
                    
                    isDepthDataEnabled = false
                    return
                }
            } else {
                isDepthDataEnabled = false
            }
        }
    }
    
    func photoSettings() -> AVCapturePhotoSettings {
        
        var settings = AVCapturePhotoSettings()
        
        if #available(iOS 11.0, *) {
            if mode.isDepthMode {
                settings.isDepthDataDeliveryEnabled = mode.isDepthMode
                settings.isDepthDataFiltered = true
            }
            else {
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
            }
        }

        settings.flashMode = flashMode
        settings.isAutoStillImageStabilizationEnabled = isImageStabilizationEnabled
        settings.isHighResolutionPhotoEnabled = true

        /// Live Photo
        if isLivePhotoEnabled {
            let livePhotoMovieFileName = NSUUID().uuidString
            let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
            settings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
        }

        return settings
    }
    
    private func remove(captureProcessor: CaptureProcessor) {
        if let pair = currentCaptureProcessors.enumerated().filter({
            $0.element.identifier == captureProcessor.identifier
        }).first {
            currentCaptureProcessors.remove(at: pair.offset)
        }
    }
    
    /* Capture a still photo from the capture device. */
//    TODO: Add intermediate thumbnail captured photo callback
//          Also, somehow combine these into one method
    public func takePhoto(_ completion: @escaping CaptureCallback) {
        
        sessionQueue.async {
    
            let settings = self.photoSettings()
            let captureProcessor = CaptureProcessor(settings: settings, livePhotoHandler: { _, _, _ in
                
            }, captureHandler: { captureProcessor, imageData, depthMap, metadata, error in
                
                self.remove(captureProcessor: captureProcessor)
                
                guard let imageData = imageData, let image = UIImage(data: imageData) else {
                    completion(nil, nil, error)
                    return
                }
                
                completion(image, metadata, nil)
            })
            
            // Keep reference to captureProcessor so delegate methods are called
            self.currentCaptureProcessors.append(captureProcessor)
            
            self.photoOutput.capturePhoto(with: settings, delegate: captureProcessor)
        }

    }
    
    public func takeLivePhoto(_ completion: @escaping LivePhotoCallback) {
        
        sessionQueue.async {
            
            let settings = self.photoSettings()
            let captureProcessor = CaptureProcessor(settings: settings, livePhotoHandler: { captureProcessor, asset, error in
                
                self.remove(captureProcessor: captureProcessor)
                
                guard let asset = asset else {
                    completion(nil, nil, nil, error)
                    return
                }
                
                PhotoLibrary.livePhoto(for: asset, completion: { livePhoto, metadata in
                    completion(livePhoto, asset, metadata, error)
                })
                
            }, captureHandler: { _, _, _, _, _ in
                
            })
            
            // Keep reference to captureProcessor so delegate methods are called
            self.currentCaptureProcessors.append(captureProcessor)
            
            self.photoOutput.capturePhoto(with: settings, delegate: captureProcessor)
        }
        
    }
  
    public var isRunning: Bool { return session.isRunning }
    public func startRunning() { session.startRunning() }
    public func stopRunning()  { session.stopRunning() }
    
    public func flip() {
        if mode.isDepthMode {
            mode = (mode == .depthFront) ? .depthRear : .depthFront
        } else {
            mode = (mode == .front) ? .back : .front
        }
    }
    
    public var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            dataOutput.connection(with: AVMediaType.video)?.videoOrientation = orientation
            photoOutput.connection(with: AVMediaType.video)?.videoOrientation = orientation
        }
    }
    
    public var mode: Mode = .back {
        didSet {
            session.apply {
                self.setupInputs()
                self.setupOutputs()
            }
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
    
    public var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure {
        didSet {
            applyCameraSetting {
                captureDevice.exposureMode = exposureMode
            }
        }
    }
    
    public func setExposureAuto() {
        applyCameraSetting {
            self.captureDevice.exposureMode = .autoExpose
        }
    }
    
    
    
    /*
     MARK: - Exposure
     
         EV = log2( aperture^2 / shutter speed )
     */
    public var minExposureDuration: Double { return captureDevice.activeFormat.minExposureDuration.seconds }
    public var maxExposureDuration: Double { return captureDevice.activeFormat.maxExposureDuration.seconds }
    public var minExposureValue: Double { return ev(from: captureDevice.activeFormat.minExposureDuration.seconds) }
    public var maxExposureValue: Double { return ev(from: captureDevice.activeFormat.maxExposureDuration.seconds) }
    
    private func ev(from duration: Double) -> Double {
        let n = Double(captureDevice.lensAperture)
        return log2((n * n) / duration)
    }
    
    private func ed(from value: Double) -> Double {
        let n = Double(captureDevice.lensAperture)
        let ed = pow(n, 2) / pow(2, value)
        return ed
    }
    
    public enum ExposureDuration: String {
        
        case ed_1_500, ed_1_250, ed_1_125, ed_1_90, ed_1_60, ed_1_30, ed_1_20,
        ed_1_15, ed_1_10, ed_1_8, ed_1_6, ed_1_4, ed_1_3, ed_1_2, ed_1,
        ed_3_2, ed_2, ed_3, ed_4, ed_6, ed_8, ed_12, ed_15, ed_24, ed_30
        
        public static var all: [ExposureDuration] = [
            .ed_1_500, .ed_1_250, .ed_1_125, .ed_1_90, .ed_1_60, .ed_1_30, .ed_1_20,
            .ed_1_15, .ed_1_10, .ed_1_8, .ed_1_6, .ed_1_4, .ed_1_3, .ed_1_2, .ed_1,
            .ed_3_2, .ed_2, .ed_3, .ed_4, .ed_6, .ed_8, .ed_12, .ed_15, .ed_24, .ed_30
        ]
        
        public var title: String {
            return rawValue.replacingOccurrences(of: "ed_", with: "").replacingOccurrences(of: "_", with: "/") + "s"
        }
        
        public var cmTime: CMTime {
            let str = rawValue.replacingOccurrences(of: "ed_", with: "")
            let components = str.components(separatedBy: "_")
            let seconds = Int64(components.first ?? "1") ?? 1
            let timescale: Int32 = components.count > 1 ? CMTimeScale(components.last ?? "1") ?? 1 : CMTimeScale(1)
            return CMTimeMake(seconds, timescale)
        }
    }
    
    private var exposureDurations: [Double] = [
        1.0/500.0, 1.0/250.0, 1.0/125.0, 1.0/90.0, 1.0/60.0, 1.0/30.0, 1.0/20.0,
        1.0/15.0, 1.0/10.0, 1.0/8.0, 1.0/6.0, 1.0/4.0, 1.0/3.0, 1.0/2.0,
        1.0,
        1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 15.0, 24.0, 30.0
    ]
    
    @objc dynamic
    public var exposureValue: Double {
        get { return ev(from: exposureDuration) }
        set { exposureDuration = ed(from: newValue) }
    }
    
    public var currentExposureDuration: ExposureDuration = .ed_1_60
    
    // Normalized
    @objc dynamic
    public var exposureDuration: Double = 0.5 {
        didSet {

            guard captureDevice.isExposureModeSupported(.custom) else {
                return
            }
            
            Tools.clamp(&exposureDuration, low: 0, high: 1)
            
            let i = Int(exposureDuration * Double(exposureDurations.count - 1))
            let expDuration = ExposureDuration.all[i]
            
            guard expDuration != currentExposureDuration else { return }
            
            currentExposureDuration = expDuration
            let cmTime = expDuration.cmTime
            
            guard !captureDevice.isAdjustingExposure,
                cmTime.seconds >= minExposureDuration,
                cmTime.seconds <= maxExposureDuration
            else { return }
            
            applyCameraSetting {
                self.captureDevice.setExposureModeCustom(duration: cmTime, iso: iso, completionHandler: nil)
            }
        }
    }
    
    @objc dynamic
    public var exposurePointOfInterest: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            guard captureDevice.isExposurePointOfInterestSupported,
                !captureDevice.isAdjustingFocus else { return }
            
            applyCameraSetting {
                captureDevice.exposurePointOfInterest = exposurePointOfInterest
                exposureMode = .autoExpose
            }
        }
    }
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.deviceInput.device
            self.applyCameraSetting {
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
            }
            
        }
    }
    
    
    /* ISO */
    public var isISOAuto: Bool {
        get {
            return captureDevice.exposureMode == .autoExpose || captureDevice.exposureMode == .continuousAutoExposure
        }
        set {
            applyCameraSetting {
                self.captureDevice.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    public var minISO: Float { return captureDevice.activeFormat.minISO }
    public var maxISO: Float { return captureDevice.activeFormat.maxISO }
    
    @objc dynamic
    public var iso: Float {
        set {
            guard !captureDevice.isAdjustingExposure,
                captureDevice.isExposureModeSupported(.custom) else {
                return
            }

//            guard newValue
            
//            var newValue = newValue
//            Tools.clamp(&newValue, low: minISO, high: maxISO)
            
            applyCameraSetting {
                self.captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: newValue, completionHandler: nil)
            }
        }
        get {
            return captureDevice.iso
        }
    }
    
    /* Focus */
    public var focusMode: AVCaptureDevice.FocusMode = .autoFocus
    
    public var isFocusAuto: Bool {
        set {
            applyCameraSetting {
                self.captureDevice.focusMode = .autoFocus
            }
        }
        get {
            return captureDevice.focusMode == .autoFocus || captureDevice.focusMode == .continuousAutoFocus
        }
    }
    
    public var lensPosition: Float {
        set {
            guard captureDevice.isFocusModeSupported(.locked) else { return }
            var newValue = newValue
            Tools.clamp(&newValue, low: 0, high: 1)
            applyCameraSetting {
                self.captureDevice.setFocusModeLocked(lensPosition: newValue, completionHandler: nil)
            }
        }
        get {
            return captureDevice.lensPosition
        }
    }
    
    /* White Balance */
    public func setWhiteBalanceAuto() {
        applyCameraSetting {
            self.captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }
    
    public var isWhiteBalanceAuto: Bool {
        return captureDevice.whiteBalanceMode == .autoWhiteBalance || captureDevice.whiteBalanceMode == .continuousAutoWhiteBalance
    }
    
    public var whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains! {
        didSet {
            guard captureDevice.isLockingWhiteBalanceWithCustomDeviceGainsSupported, !captureDevice.isAdjustingWhiteBalance else {
                return
            }
            applyCameraSetting {
                // TODO: This is causing some weird tint
//                self.captureDevice.setWhiteBalanceModeLocked(with: self.whiteBalanceGains, completionHandler: nil)
            }
        }
    }
    
    /// Converts normalized components to whiteBalance values 
    public func setWhiteBalance(red: Float, green: Float, blue: Float) {
        guard var whiteBalanceGains = self.whiteBalanceGains else { return }
        
        let max = self.captureDevice.maxWhiteBalanceGain
        whiteBalanceGains.redGain   = Tools.convert(red  , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
        whiteBalanceGains.greenGain = Tools.convert(green, oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
        whiteBalanceGains.blueGain  = Tools.convert(blue , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
        self.whiteBalanceGains = whiteBalanceGains
    }
    
    public var tint: UIColor! {
        didSet {
            if let components = self.tint.components() {
                setWhiteBalance(red: Float(components.red), green: Float(components.green), blue: Float(components.blue))
            }
        }
    }
    
    public func isModeSupported(_ mode: Mode) -> Bool {
        return Mode.supportedModes.contains(mode)
    }
    
    // MARK: - Mode
    public enum Mode: String {
        
        case back
        case front
        case telephoto
        case dual
        case depthRear
        case depthFront
        
        func device() -> AVCaptureDevice? {
            
            var position: AVCaptureDevice.Position = .unspecified
            var deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
            let mediaType: AVMediaType = .video
            
            switch self {
            case .back:
                position = .back
                deviceType = .builtInWideAngleCamera
//                if #available(iOS 10.2, *) { deviceType = .builtInDualCamera }
//                else                       { deviceType = .builtInDuoCamera }
//
//                if AVCaptureDevice.default(deviceType, for: .video, position: .back) == nil {
//                    deviceType = .builtInWideAngleCamera
//                }
            case .front:
                position = .front
            case .dual, .depthRear:
                position = .back
                if #available(iOS 10.2, *) { deviceType = .builtInDualCamera }
                else                       { deviceType = .builtInDuoCamera }
            case .depthFront:
                position = .front
                if #available(iOS 11.1, *) { deviceType = .builtInTrueDepthCamera }
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
        
        public var title: String { return rawValue.capitalized }
        
        public static var supportedModes: [Mode] {
            var modes: [Mode] = [.back, .front]
            
            var additionalTypes: [AVCaptureDevice.DeviceType] = [.builtInTelephotoCamera]
            if #available(iOS 10.2, *) {
                additionalTypes += [AVCaptureDevice.DeviceType.builtInDualCamera]
            } else {
                additionalTypes += [AVCaptureDevice.DeviceType.builtInDuoCamera]
            }
            
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: additionalTypes, mediaType: .video, position: .back)
            if discoverySession.devices.count > 0 {
                modes += [.dual, .telephoto, .depthRear, .depthFront]
            }
            
            return modes
        }
        
        var isDepthMode: Bool {
            return self == .depthFront || self == .depthRear
        }
        
        public static var all: [Mode] {
            return [.back, .front, .dual, .telephoto, .depthRear, .depthFront]
        }
        
        public var capturePosition: AVCaptureDevice.Position {
            switch self {
            case .back, .dual, .telephoto, .depthRear: return .back
            case .front, .depthFront: return .front
            }
        }
        
        public static func mode(for position: AVCaptureDevice.Position) -> Mode {
            return position == .front ? .front : .back
        }
    }
    
    public var captureDevice: AVCaptureDevice!
    
    /// Internal
    var session: AVCaptureSession
    var photoOutput: AVCapturePhotoOutput
    var dataOutput: AVCaptureVideoDataOutput
    var dataOutputQueue: DispatchQueue = DispatchQueue(label: "VideoDataOutputQueue")
    var depthDataOutput: AVCaptureOutput?
    var deviceInput: AVCaptureDeviceInput!
    
    /// Private
    private let depthDataCallbackQueue = DispatchQueue(label: "DepthDataOutputQueue")
    private let sessionQueue = DispatchQueue(label: "session queue")
    fileprivate var currentCaptureProcessors: [CaptureProcessor] = []
    
    private var videoOutputSynchronizer: Any?
    @available(iOS 11.0, *)
    private var videoDataOutputSynchronizer: AVCaptureDataOutputSynchronizer? {
        get { return videoOutputSynchronizer as? AVCaptureDataOutputSynchronizer }
        set { videoOutputSynchronizer = newValue }
    }
    
    
    private var captureDeviceObserver: Observer<AVCaptureDevice>?
    
}


// MARK: - Setup
extension CameraBase {
    
    func setupAVDevice() {

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
        
        if mode == .front || mode == .depthFront {
            dataOutput.connection(with: .video)?.isVideoMirrored = true
        }
        
        orientation = .portrait
    }
    
    func setupOutputs() {
        
        session.outputs.forEach { self.session.removeOutput($0) }
        
        // Data Output
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            
            dataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String : kCMPixelFormat_32BGRA
            ]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        }
        
        // Capture Photo Output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            if #available(iOS 11.0, *) { photoOutput.isDepthDataDeliveryEnabled = mode.isDepthMode }
            photoOutput.isHighResolutionCaptureEnabled = true
            isLivePhotoEnabled = true
        }
        
        // Depth Data Output
        if #available(iOS 11.0, *), mode.isDepthMode {
            
            depthDataOutput = AVCaptureDepthDataOutput()
            
            let output = depthDataOutput as! AVCaptureDepthDataOutput
            output.setDelegate(self, callbackQueue: depthDataCallbackQueue)
            output.alwaysDiscardsLateDepthData = true
            output.isFilteringEnabled = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                
                videoOutputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [dataOutput, output])
                videoDataOutputSynchronizer?.setDelegate(self, queue: depthDataCallbackQueue)
            }
        }
        
        orientation = .portrait
    }

}

// MARK: -  Editing
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

extension CameraBase: AVCaptureDataOutputSynchronizerDelegate {
    
    @available(iOS 11.0, *)
    public func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {

    }
}


// MARK: - Depth
// MARK: AVCaptureDepthDataOutputDelegate
extension CameraBase: AVCaptureDepthDataOutputDelegate {
    
    @available(iOS 11.0, *)
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {

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

public typealias LivePhotoCallback = ((_ livePhoto: PHLivePhoto?, _ asset: PHAsset?, _ metadata: [AnyHashable:Any]?, _ error: Error?) -> ())
public typealias CaptureCallback = ((_ photo: UIImage?, _ metadata: PhotoMetadata?, _ error: Error?) -> ())



open class Observer<T: NSObject> {
    
    public typealias ChangeHandler = ((_ observee: T, _ keyPath: PartialKeyPath<T>) -> ())
    
    public let observee: T
    public let keyPaths: [AnyKeyPath]
    
    deinit {
        observers.forEach { $0.invalidate() }
    }
    
    public init(observee: T, keyPaths: [AnyKeyPath], changeHandler: @escaping ChangeHandler) {
        self.observee = observee
        self.keyPaths = keyPaths
        
        for kp in keyPaths {
            if let keyPath = kp as? KeyPath<T, Float> {
                observers.append(observee.observe(keyPath, changeHandler: { (captureDevice, change) in
                    changeHandler(observee, keyPath)
                }))
            }
            else if let keyPath = kp as? KeyPath<T, Double> {
                observers.append(observee.observe(keyPath, changeHandler: { (captureDevice, change) in
                    changeHandler(observee, keyPath)
                }))
            }
        }
    }
    
    private var observers: [NSKeyValueObservation] = []
}
