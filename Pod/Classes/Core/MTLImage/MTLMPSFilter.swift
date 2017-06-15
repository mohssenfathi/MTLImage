//
//  MPS.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import  MetalPerformanceShaders

public
class MPS: MTLFilter {
    
    var kernel: MPSKernel!

    public override init(functionName: String?) {
        super.init(functionName: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func process() {
        
        guard let inputTexture = input?.texture, let texture = texture else { return }
        
        input?.processIfNeeded()
        
        autoreleasepool {
            
            let commandBuffer = context.commandQueue.makeCommandBuffer()
            commandBuffer.label = "MTLFilter: " + title
            
            (kernel as? MPSUnaryImageKernel)?.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: texture)

            configureCommandBuffer(commandBuffer)
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                self.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func configureCommandBuffer(_ commandBuffer: MTLCommandBuffer) {
        // Needs to be subclassed
    }
    

}
