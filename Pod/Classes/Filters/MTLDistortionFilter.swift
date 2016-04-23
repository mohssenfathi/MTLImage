//
//  MTLDistortionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/22/16.
//
//

import UIKit

struct DistortionUniforms {
    var centerX: Float = 0.5;
    var centerY: Float = 0.5;
}

public
class MTLDistortionFilter: MTLFilter {
    
    var uniforms = DistortionUniforms()
    
    public var x: Float = 0.5 {
        didSet {
            clamp(&x, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public var y: Float = 0.5 {
        didSet {
            clamp(&y, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "distortion")
        title = "Distortion"
        properties = [MTLProperty(key: "x", title: "X"),
                      MTLProperty(key: "y", title: "Y")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.centerX = x
        uniforms.centerY = y
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(DistortionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}
