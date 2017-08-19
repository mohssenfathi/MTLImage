//
//  PerlinNoise.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/22/16.
//
//

import UIKit

struct PerlinNoiseUniforms: Uniforms {
    var scale: Float = 0.5
}

public
class PerlinNoise: Filter {
    
    var uniforms = PerlinNoiseUniforms()
    
    public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "perlinNoise")
        title = "Perlin Noise"
        properties = [Property(key: "scale", title: "Scale")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.scale = scale * 20
        updateUniforms(uniforms: uniforms)
    }
    
}
