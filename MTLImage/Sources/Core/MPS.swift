
//
//  MPS.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class MPS: Filter {
    
    var kernel: MPSKernel!

    public override init(functionName: String?) {
        super.init(functionName: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override var needsUpdate: Bool {
        didSet {
            if needsUpdate == true {
                for target in targets {
                    if var object = target as? MTLObject {
                        object.setNeedsUpdate()
                    }
                    else if let view = target as? View {
                        view.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    public override func process() {
        
        if texture == nil {
            initTexture()
        }
        
        input?.processIfNeeded()
        
        guard let inputTexture = input?.texture,
            let texture = texture,
            let commandBuffer = context.commandQueue.makeCommandBuffer() else { return }
        
        autoreleasepool {
            
            commandBuffer.label = "Filter: " + title
            
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
