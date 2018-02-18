//
//  YCbCrToRGB.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/16/18.
//

import MetalKit

struct YCbCrToRGBUniforms: Uniforms {
    var transformMatrix: float4x4 = float4x4(
        float4(1, 0, 0, 0),
        float4(0, 1, 0, 0),
        float4(0, 0, 1, 0),
        float4(0, 0, 0, 1)
    )
}

public class YCbCrToRGB: Filter {

    var Y: MTLTexture?
    var CbCr: MTLTexture?
    var transform: CGAffineTransform = .identity
    
    var uniforms = YCbCrToRGBUniforms()
    
    init() {
        super.init(functionName: "YCbCrToRGB")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        
        uniforms.transformMatrix = float4x4(
            float4(Float(transform.a), Float(transform.b), 0, 0),
            float4(Float(transform.c), Float(transform.d), 0, 0),
            float4(Float(transform.tx), Float(transform.ty), 1, 0),
            float4(0, 0, 0, 1)
        )
        
        updateUniforms(uniforms: uniforms, size: MemoryLayout<YCbCrToRGBUniforms>.size)
    }
    
    
    open override func process() {
        
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer() else { return }
        
        autoreleasepool {
            
            encode(to: commandBuffer)
            
            commandBuffer.addCompletedHandler({ [weak self] (commandBuffer) in
                
                guard let weakSelf = self else { return }
                
                weakSelf.didFinishProcessing(weakSelf)
                weakSelf.newTextureAvailable?(weakSelf)
                if weakSelf.continuousUpdate || (weakSelf.input?.continuousUpdate ?? false) { return }
                self?.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    override func encode(to commandBuffer: MTLCommandBuffer) {
        
        if texture == nil {
            initTexture()
        }
        
        guard let Y = Y, let CbCr = CbCr,
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSize(width: (Y.width + w - 1) / w, height: (Y.height + h - 1) / h, depth: 1)
        
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        commandEncoder.setTexture(texture, index: 0)
        commandEncoder.setTexture(Y, index: 1)
        commandEncoder.setTexture(CbCr, index: 2)
        
        configureCommandEncoder(commandEncoder)
        
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        
    }
    
    override func initTexture() {
        
        guard let Y = Y else { return }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: Y.width,
                                                                         height: Y.height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        texture = context.device?.makeTexture(descriptor: textureDescriptor)
    }
}
