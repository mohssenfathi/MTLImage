//
//  MTLPerlinNoiseFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/22/16.
//
//

import UIKit

struct PerlinNoiseUniforms {
    var scale: Float = 0.5
}

public
class MTLPerlinNoiseFilter: MTLFilter {
    
    var uniforms = PerlinNoiseUniforms()
    
    public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "perlinNoise")
        title = "Perlin Noise"
        properties = [MTLProperty(key: "scale", title: "Scale")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.scale = scale
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(PerlinNoiseUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}
