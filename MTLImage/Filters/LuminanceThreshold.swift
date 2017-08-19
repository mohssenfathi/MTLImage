//
//  LuminanceThreshold.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/24/16.
//
//

import UIKit

struct LuminanceThresholdUniforms : Uniforms{
    var threshold: Float = 0.5;
}

public
class LuminanceThreshold: Filter {
    
    var uniforms = LuminanceThresholdUniforms()
    
    public var threshold: Float = 0.5 {
        didSet {
            clamp(&threshold, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "luminanceThreshold")
        title = "Luminance Threshold"
        properties = [Property(key: "threshold", title: "Threshold")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.threshold = threshold
        updateUniforms(uniforms: uniforms)
    }
    
}
