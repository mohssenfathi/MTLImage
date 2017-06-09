//
//  PixelBufferRenderer.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/8/17.
//

import AVFoundation

class PixelBufferRenderer: MTLFilter {
    
    override init(functionName: String?) {
        super.init(functionName: functionName)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        
        reset()
        
        outputPixelBufferPool = PixelBufferRenderer.allocateOutputBufferPool(with: formatDescription,
                                                                                   outputRetainedBufferCountHint: outputRetainedBufferCountHint)
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
    
    override func process() {
        
        guard let inputPixelBuffer = input?.outputPixelBuffer() else { return }
        
        
    }
    
    func resetBuffers() {
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
        isPrepared = false
    }
    
    private(set) var inputFormatDescription: CMFormatDescription?
    private(set) var outputFormatDescription: CMFormatDescription?
    private var inputTextureFormat: MTLPixelFormat = .invalid
    private var outputPixelBufferPool: CVPixelBufferPool!
    private var textureCache: CVMetalTextureCache!
    private var isPrepared: Bool = false
}


extension PixelBufferRenderer {
    
    static private func allocateOutputBufferPool(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) -> CVPixelBufferPool? {
        
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
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
