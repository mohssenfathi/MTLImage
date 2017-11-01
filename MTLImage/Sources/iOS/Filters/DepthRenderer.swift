//
//  DepthRenderer.swift
//  MTLImage-iOS10.0
//
//  Created by Mohssen Fathi on 6/9/17.
//

import AVFoundation
import CoreVideo

struct DepthRendererUniforms: Uniforms {
    var offset: Float = 0.0
    var range: Float = 1.0
}

public
class DepthRenderer: Filter {
    
    var uniforms = DepthRendererUniforms()
    
    @objc public var offset: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var range: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    
    public init() {
        super.init(functionName: "depthRenderer")
        title = "Depth Renderer"
        properties = [
//            Property(key: "offset", title: "Offset"),
//            Property(key: "range", title: "Range")
        ]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func update() {
        if self.input == nil { return }
        
        if let context = (source as? Camera)?.depthContext {
            if context.minDepth < offset { offset = context.minDepth }
            if context.maxDepth < range  { range  = context.maxDepth }
        }
        
        uniforms.offset = offset
        uniforms.range = range
        updateUniforms(uniforms: uniforms)
    }
    
    func resetProcess() {
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
    }
    
    override public func process() {
        
        guard let inputPixelBuffer = (input as? Camera)?.depthPixelBuffer else { return }
        
        var depthFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, inputPixelBuffer, &depthFormatDescription)
        prepare(with: depthFormatDescription!, outputRetainedBufferCountHint: 2)
        render(pixelBuffer: inputPixelBuffer)
    }
    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        
        resetProcess()
        
        outputPixelBufferPool = DepthRenderer.allocateOutputBufferPool(with: formatDescription, outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        
        var pixelBuffer: CVPixelBuffer?
        var pixelBufferFormatDescription: CMFormatDescription?
        _ = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &pixelBufferFormatDescription)
        }
        pixelBuffer = nil
        
        inputFormatDescription = formatDescription
        outputFormatDescription = pixelBufferFormatDescription
        
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
        if inputMediaSubType == kCVPixelFormatType_DepthFloat16 ||
            inputMediaSubType == kCVPixelFormatType_DisparityFloat16 {
            inputTextureFormat = .r16Float
        } else if inputMediaSubType == kCVPixelFormatType_DepthFloat32 ||
            inputMediaSubType == kCVPixelFormatType_DisparityFloat32 {
            inputTextureFormat = .r32Float
        } else {
            assertionFailure("Input format not supported")
        }
        
        var metalTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) != kCVReturnSuccess {
            assertionFailure("Unable to allocate depth converter texture cache")
        } else {
            textureCache = metalTextureCache
        }
        
        isPrepared = true
    }
    
    @discardableResult
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        
        if !isPrepared {
            assertionFailure("Invalid state: Not prepared")
            return nil
        }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &newPixelBuffer)
        guard let outputPixelBuffer = newPixelBuffer else {
            print("Allocation failure: Could not get pixel buffer from pool (\(self.description))")
            return nil
        }
        
        texture = outputPixelBuffer.mtlTexture(textureCache: textureCache, pixelFormat: .bgra8Unorm)
        
        guard let outputTexture = texture,
            let inputTexture = pixelBuffer.mtlTexture(textureCache: textureCache, pixelFormat: inputTextureFormat),
            let commandBuffer = context.commandQueue?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return nil
        }
        
        autoreleasepool {
            
            commandEncoder.label = title
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(inputTexture, index: 0)
            commandEncoder.setTexture(outputTexture, index: 1)
            
            self.configureCommandEncoder(commandEncoder)
            
            let w = pipeline.threadExecutionWidth
            let h = pipeline.maxTotalThreadsPerThreadgroup / w
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
            let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + w - 1) / w, height: (inputTexture.height + h - 1) / h, depth: 1)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            
            commandEncoder.endEncoding()
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                
                if self.continuousUpdate { return }
                if let input = self.input {
                    if input.continuousUpdate { return }
                }
                self.needsUpdate = false
                
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        
        return outputPixelBuffer
        
    }
    
    
    private var outputPixelBufferPool: CVPixelBufferPool!
    private var textureCache: CVMetalTextureCache!
    private var outputFormatDescription: CMFormatDescription?
    private var inputFormatDescription: CMFormatDescription?
    private var inputTextureFormat: MTLPixelFormat = .r16Float
    private var isPrepared: Bool = false
}

// Depth
extension DepthRenderer {
    
    static private func allocateOutputBufferPool(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int, size: CMVideoDimensions? = nil) -> CVPixelBufferPool? {
        
        let inputDimensions = size ??  CMVideoFormatDescriptionGetDimensions(formatDescription)
        let outputPixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        // Create a pixel buffer pool with the same pixel attributes as the input format description
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, outputPixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not create pixel buffer pool")
            return nil
        }
        return pixelBufferPool
    }
}


extension CVPixelBuffer {
    
    func mtlTexture(textureCache: CVMetalTextureCache, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(self);
        let height = CVPixelBufferGetHeight(self);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, self, nil, pixelFormat, width, height, 0, &cvMetalTexture)
        
        guard let cvMetalTex = cvMetalTexture else { return nil }
        return CVMetalTextureGetTexture(cvMetalTex)
    }
    
    public var mtlPixelFormat_Depth: MTLPixelFormat? {
        
        // Format Description
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, self, &formatDescription)
        guard formatDescription != nil else { return nil }
        
        // Pixel Format
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription!)
        if inputMediaSubType == kCVPixelFormatType_DepthFloat16 || inputMediaSubType == kCVPixelFormatType_DisparityFloat16 {
            return .r16Float
        } else if inputMediaSubType == kCVPixelFormatType_DepthFloat32 || inputMediaSubType == kCVPixelFormatType_DisparityFloat32 {
            return .r32Float
        } else {
            return nil
        }
    }
    
}


@available(iOS 11.0, *)
extension AVDepthData {
    
    func mtlTexture(textureCache: CVMetalTextureCache) -> MTLTexture? {
        
        let pixelBuffer = depthDataMap
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard let textureFormat = pixelBuffer.mtlPixelFormat_Depth else { return nil }
        
        if CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorSystemDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvMetalTexture) != kCVReturnSuccess {
            return nil
        }
        
        guard let cvMetalTex = cvMetalTexture else { return nil }
        let texture = CVMetalTextureGetTexture(cvMetalTex)
        
        return texture
    }
    
}
