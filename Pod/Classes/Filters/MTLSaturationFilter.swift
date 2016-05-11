//
//  MTLSaturationFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct SaturationUniforms {
    var saturation: Float = 0.5
}

public
class MTLSaturationFilter: MTLFilter {
    
    var uniforms = SaturationUniforms()
    
    public var saturation: Float = 0.5 {
        didSet {
            clamp(&saturation, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "saturation")
        title = "Saturation"
        properties = [MTLProperty(key: "saturation", title: "Saturation")]
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.saturation = saturation * 2.0
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(SaturationUniforms), options: .CPUCacheModeDefaultCache)
    }
    
//    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder?) {
//        var uniforms = AdjustSaturationUniforms(saturation: saturation)
//
//        if uniformBuffer == nil {
//            uniformBuffer = context.device?.newBufferWithLength(sizeofValue(uniforms), options: .CPUCacheModeDefaultCache)
//        }
//        
//        memcpy(uniformBuffer.contents(), &uniforms, sizeofValue(uniforms))
//        commandEncoder?.setBuffer(uniformBuffer, offset: 0, atIndex: 0)
//    }
    
}
