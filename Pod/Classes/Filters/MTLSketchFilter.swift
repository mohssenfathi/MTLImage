//
//  MTLSketchFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct SketchUniforms {
    var intensity: Float = 0.5;
}

public
class MTLSketchFilter: MTLFilter {
    var uniforms = SketchUniforms()
    
    public var intensity: Float = 0.0 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "sketch")
        title = "Sketch"
        properties = [MTLProperty(key: "intensity", title: "Intensity")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.intensity = intensity * 3.0 + 0.2
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(SketchUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}
