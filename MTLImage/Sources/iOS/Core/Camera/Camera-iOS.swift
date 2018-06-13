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
class Camera: CameraBase, Input {
    
    public var title: String = "Camera"
    public var id: String = UUID().uuidString
    public var continuousUpdate: Bool { return true }
    public var videoTexture: MTLTexture?
    
    /* MTLFilters added to this group will filter the camera output */
    public var filterGroup = FilterGroup()
    
    /*  Init  */
    public override init() {
        super.init()
        
        title = "MTLCamera"
    
        pixelBufferConverter = PixelBufferToMTLTexture(device: device)
        setupPipeline()
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.makeFunction(name: "camera")
        do {
            pipeline = try context.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    public func didFinishProcessing() {
        context.semaphore.signal()
    }
    
    public var processingSize: CGSize! {
        didSet { context.processingSize = processingSize }
    }
    
    public var needsUpdate: Bool = true {
        didSet {
            for target in targets {
                if var inp = target as? Input { inp.setNeedsUpdate() }
            }
        }
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
    
    
    //    MARK: - Processing
    public func process() {
        
        guard let videoTexture = videoTexture else { return }
        
        if texture == nil || texture!.width != videoTexture.width || texture!.height != videoTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: videoTexture.pixelFormat, width:videoTexture.width, height: videoTexture.height, mipmapped: false)
            texture = context.device?.makeTexture(descriptor: textureDescriptor)
        }
        
        guard let texture = texture else { return }

        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w, height: (texture.height + h - 1) / h, depth: 1)
        
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.needsUpdate = false
        }
        
        
        commandEncoder.setComputePipelineState(pipeline)
        
        commandEncoder.setTexture(videoTexture, index: 0)
        commandEncoder.setTexture(texture, index: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    
    //    MARK: - Input
    public var texture: MTLTexture?
    public var context: Context { return internalContext }
    public var commandBuffer: MTLCommandBuffer? { return context.commandQueue?.makeCommandBuffer() }
    public var device: MTLDevice { return context.device }
    public var targets: [Output] = []
    
    public func addTarget(_ target: Output) {
        
        var t = target
        targets.append(t)
        t.input = self

        if !isRunning {
            startRunning()
        }
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
        //      TODO:   remove from internalTargets
    }
    
    public func removeAllTargets() {
        //        for var target in internalTargets {
        //            target.input = nil
        //        }
        targets.removeAll()
        stopRunning()
    }
    
    
    public var depthPixelBuffer: CVPixelBuffer?
    
//    MARK: - Internal
    var currentSampleBuffer: CMSampleBuffer?
    var internalContext: Context = Context()
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    var pixelBufferConverter: PixelBufferToMTLTexture?
}

extension Camera: DepthInput { }

extension Camera {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideoData(sampleBuffer: sampleBuffer)
    }


    @available(iOS 11.0, *)
    public override func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        if mode.isDepthMode,
            let depthDataOutput = depthDataOutput,
            let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            if !syncedDepthData.depthDataWasDropped {
                let depthData = syncedDepthData.depthData
                processDepthData(depthData)
            }
        }

        if let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: dataOutput) as? AVCaptureSynchronizedSampleBufferData {
            if !syncedVideoData.sampleBufferWasDropped {
                processVideoData(sampleBuffer: syncedVideoData.sampleBuffer)
            }
        }
        
    }
    
    func processVideoData(sampleBuffer: CMSampleBuffer) {
        
        // TODO: Put on processing thread?
        currentSampleBuffer = sampleBuffer
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if let texture = pixelBufferConverter?.convert(pixelBuffer: pixelBuffer) {
            self.texture = texture
        }
        
        DispatchQueue.main.async {
            self.needsUpdate = true
        }
    }
    
    @available(iOS 11.0, *)
    func processDepthData(_ depthData: AVDepthData) {
        
        // TODO: Sometimes this is failing. Find out why
        var depthData = depthData.applyingExifOrientation(CGImagePropertyOrientation.right)
        
        if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }
        depthData.depthDataMap.normalize()
        depthPixelBuffer = depthData.depthDataMap
    }
}

public
extension Camera {
    public func snapshot() -> UIImage? { return texture?.image }
}
