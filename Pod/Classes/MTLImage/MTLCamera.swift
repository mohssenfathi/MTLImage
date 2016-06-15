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
class MTLCamera: NSObject, MTLInput, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var internalTargets = [MTLOutput]()
    private var internalTexture: MTLTexture!
    private var videoTexture: MTLTexture!
    var internalContext: MTLContext = MTLContext()
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var dataOutput: AVCaptureVideoDataOutput!
    var dataOutputQueue: DispatchQueue!
    var deviceInput: AVCaptureDeviceInput!
    var textureCache: Unmanaged<CVMetalTextureCache>?

    public override init() {
        super.init()
        self.title = "MTLCamera"
        setupAVDevice()
        setupPipeline()
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
        
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCMPixelFormat_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: DispatchQueueAttributes.serial)
        dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        }
        
        let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.isEnabled = true
        connection?.videoOrientation = .portrait

        session.commitConfiguration()
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

}
