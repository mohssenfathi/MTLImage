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
    
    /* MTLFilters added to this group will filter the camera output */
    public var filterGroup = FilterGroup()
    
    /*  Init  */
    public override init() {
        super.init()
        
        title = "MTLCamera"
        
        CVMetalTextureCacheCreate(kCFAllocatorSystemDefault, nil, device, nil, &textureCache)
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
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
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
    
    
    //    MARK: - MTLInput
    public var texture: MTLTexture?
    public var context: Context { return internalContext }
    public var commandBuffer: MTLCommandBuffer? { return context.commandQueue?.makeCommandBuffer() }
    public var device: MTLDevice { return context.device }
    public var targets: [Output] { return internalTargets }
    
    public func addTarget(_ target: Output) {
        var t = target
        internalTargets.append(t)
        t.input = self
        startRunning()
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
        internalTargets.removeAll()
        stopRunning()
    }

    
//    MARK: - Internal
    private var internalTargets = [Output]()
    public var videoTexture: MTLTexture?
    var internalContext: Context = Context()
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    var textureCache: CVMetalTextureCache?
}


extension Camera {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer);
        let height = CVPixelBufferGetHeight(pixelBuffer);
        
        guard let textureCache = textureCache else { return }
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvMetalTexture)
        
        guard let cvMetalTex = cvMetalTexture else { return }
        texture = CVMetalTextureGetTexture(cvMetalTex)
        
        DispatchQueue.main.async {
            self.needsUpdate = true
        }
        
    }
}

public
extension Camera {
    public func snapshot() -> UIImage? { return texture?.image }
}
