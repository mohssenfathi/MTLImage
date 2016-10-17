//
//  MTLMPSFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import  MetalPerformanceShaders

public
class MTLMPSFilter: MTLFilter {
    
    var kernel: MPSKernel!

    public override init(functionName: String?) {
        super.init(functionName: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func process() {
        
        // TODO: Look info fallback allocators
        
        guard needsUpdate == true else { return }
        
        guard let inputTexture = input?.texture else { return }
        
        autoreleasepool {
            if internalTexture == nil || internalTexture!.width != inputTexture.width || internalTexture!.height != inputTexture.height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat, width:inputTexture.width,
                                                                                 height: inputTexture.height, mipmapped: false)
                internalTexture = context.device?.makeTexture(descriptor: textureDescriptor)
            }
            
            let threadgroupCounts = MTLSizeMake(8, 8, 1)
            let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
            
            let commandBuffer = context.commandQueue.makeCommandBuffer()
            commandBuffer.label = "MTLFilter: " + title
            
            (kernel as? MPSUnaryImageKernel)?.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: internalTexture!)

            configureCommandBuffer(commandBuffer)
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                self.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func configureCommandBuffer(_ commandBuffer: MTLCommandBuffer) {
        // Needs to be subclasses
    }
    

}
