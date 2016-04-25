//
//  MTLLuminanceThresholdFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/24/16.
//
//

import UIKit

struct LuminanceThresholdUniforms {
    var threshold: Float = 0.5;
}

public
class MTLLuminanceThresholdFilter: MTLFilter {
    
    var uniforms = LuminanceThresholdUniforms()
    
    public var threshold: Float = 0.5 {
        didSet {
            clamp(&threshold, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "luminanceThreshold")
        title = "LuminanceThreshold"
        properties = [MTLProperty(key: "threshold", title: "Threshold")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.threshold = threshold
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(LuminanceThresholdUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}