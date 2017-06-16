//
//  MTLCNNFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/20/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class MTLCNNFilter: MTLFilter {

    var kernel: MPSCNNKernel!
    var inputImage, outputImage: MPSImage?
    
    public override init(functionName: String) {
        super.init(functionName: "EmptyShader")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func process() {
        
        // Look info fallback allocators
        
        guard let inputTexture = input?.texture else {
            print("input texture nil")
            return
        }
        
        autoreleasepool {
            if internalTexture == nil || internalTexture!.width != inputTexture.width || internalTexture!.height != inputTexture.height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(with: inputTexture.pixelFormat, width:inputTexture.width,
                                                                                 height: inputTexture.height, mipmapped: false)
                internalTexture = context.device?.newTexture(with: textureDescriptor)
            }
            
            let threadgroupCounts = MTLSizeMake(8, 8, 1)
            let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
            
            let commandBuffer = context.commandQueue.commandBuffer()
            commandBuffer.label = "MTLFilter: " + title
            
            configureCommandBuffer(commandBuffer: commandBuffer)
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                self.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func configureCommandBuffer(commandBuffer: MTLCommandBuffer) {
        // Needs to be subclassed
    }
}
