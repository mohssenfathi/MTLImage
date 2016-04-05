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
            if saturation < 0.0 { saturation = 0.0 }
            if saturation > 1.0 { saturation = 1.0 }
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "saturation")
        title = "Saturation"
        properties = [MTLProperty(key: "saturation", title: "Saturation")]
        
        update()
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
