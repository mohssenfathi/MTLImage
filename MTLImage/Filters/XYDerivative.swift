//
//  XYDerivative.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

struct XYDerivativeUniforms: Uniforms {
    var edgeStrength: Float = 0.5
}

public
class XYDerivative: Filter {
    
    var uniforms = XYDerivativeUniforms()
    
    var edgeStrength: Float = 0.5 {
        didSet {
            clamp(&edgeStrength, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "xyDerivative")
        title = "XY Derivative"
        properties = [Property(key: "edgeStrength", title: "Edge Strength")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.edgeStrength = edgeStrength * 3.0 + 0.2
        updateUniforms(uniforms: uniforms)
    }
    
}
