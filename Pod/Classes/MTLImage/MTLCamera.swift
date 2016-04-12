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
    var internalContext: MTLContext = MTLContext()
    var pipeline: MTLComputePipelineState!
    var dirty: Bool!
    
    var session: AVCaptureSession!
    var dataOutput: AVCaptureVideoDataOutput!
    var dataOutputQueue: dispatch_queue_t!
    var deviceInput: AVCaptureDeviceInput!
    var textureCache: Unmanaged<CVMetalTextureCache>?

    public override init() {
        super.init()
        self.title = "MTLCamera"
        setupAVDevice()
    }
    
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//    
//    public required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//    
//    func commonInit() {
////        self.processingSize = image.size
//        self.title = "MTLCamera"
//    }
    
    func setupAVDevice() {
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        try! deviceInput = AVCaptureDeviceInput(device: captureDevice)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        dataOutput = AVCaptureVideoDataOutput()
//        dataOutput.videoSettings = [NSNumber(unsignedInt: kCMPixelFormat_32BGRA) : kCVPixelBufferPixelFormatTypeKey]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)
        dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        }
        dataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true
        
        session.startRunning()
    }
    
    
//    MARK: - SampleBuffer Delegate
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        // Y: luma
        
        var yTextureRef : Unmanaged<CVMetalTextureRef>?
        
        let yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 0);
        let yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 0);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache!.takeUnretainedValue(),
                                                  pixelBuffer!,
                                                  nil,
                                                  MTLPixelFormat.R8Unorm,
                                                  yWidth, yHeight, 0,
                                                  &yTextureRef)
        
        // CbCr: CB and CR are the blue-difference and red-difference chroma components /
        
        var cbcrTextureRef : Unmanaged<CVMetalTextureRef>?
        
        let cbcrWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 1);
        let cbcrHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 1);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache!.takeUnretainedValue(),
                                                  pixelBuffer!,
                                                  nil,
                                                  MTLPixelFormat.RG8Unorm,
                                                  cbcrWidth, cbcrHeight, 1,
                                                  &cbcrTextureRef)
        
        
        let yTexture = CVMetalTextureGetTexture((yTextureRef?.takeUnretainedValue())!)
        internalTexture = CVMetalTextureGetTexture((cbcrTextureRef?.takeUnretainedValue())!)
        
//        self.metalView.addTextures(yTexture: yTexture!, cbcrTexture: cbcrTexture!)
        
        yTextureRef?.release()
        cbcrTextureRef?.release()
        
//        internalTexture = texture(CMSampleBufferGetImageBuffer(sampleBuffer)!)
    }
    
    func texture(imageBuffer: CVImageBuffer) -> MTLTexture? {

        let width  = CVPixelBufferGetWidthOfPlane(imageBuffer, 1);
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
        let pixelFormat = MTLPixelFormat.R8Unorm
        
        var texture: Unmanaged<CVMetalTextureRef>?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache!.takeUnretainedValue(), imageBuffer, nil, pixelFormat, width, height, 0, &texture)
        
        var metalTexture: MTLTexture?
        if status == kCVReturnSuccess {
            metalTexture = CVMetalTextureGetTexture((texture?.takeUnretainedValue())!);
            texture?.release()
        }
        
        return metalTexture
    }
    
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
    
    public var processingSize: CGSize! {
        didSet {
            loadTexture()
            context.processingSize = processingSize
        }
    }
    
    public func setNeedsUpdate() {
        for target in targets {
            if let filter = target as? MTLFilter {
                filter.dirty = true
            }
        }
    }
    
    public func setProcessingSize(processingSize: CGSize, respectAspectRatio: Bool) {
        var size = processingSize
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
    
    func loadTexture() {
        let flip = false
//        self.internalTexture = image.texture(device, flip: flip, size: processingSize)
    }
    
    func chainLength() -> Int {
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
        return c
    }
    
    func length(target: MTLOutput) -> Int {
        var c = 1
        
        if let input = target as? MTLInput {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }
        
        return c
        
        //        var c = count
        //        if let input = target as? MTLInput {
        //            for t in input.targets {
        //                c = c + length(target, count: c)
        //            }
        //        }
        //        return c
    }
    
    //    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            return self.internalTexture
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
    
    
    public func addTarget(target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        loadTexture()
        t.input = self
    }
    
    public func removeTarget(target: MTLOutput) {
        var t = target
        t.input = nil
        //      TODO:   remove from internalTargets
    }
    
    public func removeAllTargets() {
        //        for var target in internalTargets {
        //            target.input = nil
        //        }
        internalTargets.removeAll()
    }

}
