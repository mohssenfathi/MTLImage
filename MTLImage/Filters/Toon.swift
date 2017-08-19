//
//  Toon.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct ToonUniforms: Uniforms {
    var quantizationLevels: Float = 0.5;
    var threshold: Float = 0.0
}

public
class Toon: Filter {
    var uniforms = ToonUniforms()
    
    public var quantizationLevels: Float = 0.5 {
        didSet {
            clamp(&quantizationLevels, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var threshold: Float = 0.5 {
        didSet {
            clamp(&threshold, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "toon")
        title = "Toon"
        properties = [Property(key: "threshold"         , title: "Threshold"          ),
                      Property(key: "quantizationLevels", title: "Quantization Levels")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.quantizationLevels = Tools.convert(quantizationLevels, oldMin: 0, oldMax: 1, newMin: 5, newMax: 15)
        uniforms.threshold = threshold * 0.8 + 0.2
        updateUniforms(uniforms: uniforms)
    }
    
}
