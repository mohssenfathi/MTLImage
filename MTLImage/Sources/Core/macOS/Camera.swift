//
//  Camera.swift
//  MTLImage_macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation
import AVFoundation

public
class Camera: NSObject, Input {
    
    public override init() {
        super.init()
        
        title = "MTLCamera"
        context.source = self
        
        setupAVDevice()
        setupPipeline()
    }
    
    public func startRunning() {
        session.startRunning()
    }
    
    public func stopRunning() {
        session.stopRunning()
    }
    
    // MARK: - Properties
    
    public var newTextureAvailable: ((MTLTexture) -> ())?
    
    public var preset: AVCaptureSession.Preset = AVCaptureSession.Preset.low {
        didSet { setupAVDevice() }
    }
    
    public var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if let connection = dataOutput.connection(with: AVMediaType.video) {
                connection.videoOrientation = orientation
            }
        }
    }
    
    public var processingSize: CGSize! {
        didSet { context.processingSize = processingSize }
    }
    
    // MARK: - Input
    public var texture: MTLTexture?
    public var context: Context = Context()
    public var device: MTLDevice { return context.device }
    public var targets: [Output] = []
    public var title: String = "Camera"
    public var id: String = UUID().uuidString
    public var continuousUpdate: Bool = true
    
    public var needsUpdate: Bool = true {
        didSet {
            for target in targets {
                if var inp = target as? Input { inp.setNeedsUpdate() }
            }
        }
    }
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
        startRunning()
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
    }
    
    public func removeAllTargets() {
        targets.removeAll()
        stopRunning()
    }

    
    // MARK: - Private
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var stillImageOutput: AVCaptureStillImageOutput!
    var dataOutput: AVCaptureVideoDataOutput!
    var dataOutputQueue: DispatchQueue!
    var deviceInput: AVCaptureDeviceInput!
    var textureCache: CVMetalTextureCache?
    
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
}


extension Camera {
    
    private func setupAVDevice() {
        
        CVMetalTextureCacheCreate(
            kCFAllocatorSystemDefault,
//            [String(kCVMetalTextureCacheMaximumTextureAgeKey) : 0.01] as CFDictionary,
            nil,
            device,
            nil,
            &textureCache
        )
        
        session = AVCaptureSession()
        session.sessionPreset = preset
        
        captureDevice = AVCaptureDevice.default(for: .video)
//        captureDevice.configureForHighestFrameRate()
        if captureDevice == nil {
            fatalError("No Capture Devices Available")
        }
        
        try! deviceInput = AVCaptureDeviceInput(device: captureDevice)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        // Sample Buffer Output
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCMPixelFormat_32BGRA),
            String(kCVPixelBufferMetalCompatibilityKey) : NSNumber(booleanLiteral: true)
        ]
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
        
        session.commitConfiguration()
    }
    
    private func setupPipeline() {
        kernelFunction = context.library?.makeFunction(name: "camera")
        do {
            pipeline = try context.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer);
        let height = CVPixelBufferGetHeight(pixelBuffer);

        guard let textureCache = textureCache else { return }
        
        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorMalloc,
            textureCache,
            pixelBuffer,
            nil,
            MTLPixelFormat.bgra8Unorm,
            width,
            height,
            0,
            &cvMetalTexture
        )

        guard result == kCVReturnSuccess,
            let cvMetalTex = cvMetalTexture else {
                return
        }
        
        texture = CVMetalTextureGetTexture(cvMetalTex)
        
        DispatchQueue.main.async {
            
            self.needsUpdate = true
            if self.texture != nil {
                self.newTextureAvailable?(self.texture!)
            }
        }
    }
    
}


extension Camera {
    
    public func didFinishProcessing() {
        context.semaphore.signal()
    }
    
    public func setProcessingSize(_ processingSize: CGSize, respectAspectRatio: Bool) {
        let size = processingSize
        if respectAspectRatio == true {
            if size.width > size.height {
                //                size.height = size.width / (image.size.width / image.size.height)
            } else {
                //                size.width = size.height * (image.size.width / image.size.height)
            }
        }
        
        self.processingSize = size
    }
    
    func chainLength() -> Int {
        if targets.count == 0 { return 1 }
        let c = length(targets.first!)
        return c
    }
    
    func length(_ target: Output) -> Int {
        var c = 1
        
        if let input = target as? Input {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }
        
        return c
    }
    
}
