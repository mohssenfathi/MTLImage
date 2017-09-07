
//
//  MPS.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

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
                        #if os(macOS)
//                            view.setNeedsDisplay(.zero)
                        #else
                            view.setNeedsDisplay()
                        #endif
                    }
                }
            }
        }
    }
    
    public override func process() {
        
        input?.processIfNeeded()
        
        if texture == nil {
            initTexture()
        }
        
        guard let inputTexture = input?.texture,
            let texture = texture,
            let commandBuffer = context.commandQueue.makeCommandBuffer() else { return }
        
        autoreleasepool {
            
            commandBuffer.label = "Filter: " + title
            
            let inPlaceTexture = UnsafeMutablePointer<MTLTexture>.allocate(capacity: 1)
            inPlaceTexture.initialize(to: inputTexture)
            
            (kernel as? MPSUnaryImageKernel)?.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: texture)

            configureCommandBuffer(commandBuffer)
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                if self.input?.continuousUpdate == false {
                    self.needsUpdate = false
                }
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func configureCommandBuffer(_ commandBuffer: MTLCommandBuffer) {
        // Needs to be subclassed
    }
    

}
