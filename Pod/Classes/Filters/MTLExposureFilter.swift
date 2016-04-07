//
//  MTLExposureFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

struct ExposureUniforms {
    var exposure: Float = 0.5;
}

public
class MTLExposureFilter: MTLFilter {
    var uniforms = ExposureUniforms()
    
    public var exposure: Float = 0.5 {
        didSet {
            clamp(&exposure, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "exposure")
        title = "Exposure"
        properties = [MTLProperty(key: "exposure", title: "Exposure")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.exposure = Tools.convert(exposure, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: -1.5, newMid: 0.0, newMax: 2.0)
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(ExposureUniforms), options: .CPUCacheModeDefaultCache)
    }
}
