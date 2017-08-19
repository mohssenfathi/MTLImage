//
//  Saturation.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct PolkaDotUniforms: Uniforms {
    var dotRadius: Float = 0.0
}

public
class PolkaDot: Filter {
    
    var uniforms = PolkaDotUniforms()
    
    public var dotRadius: Float = 0.0 {
        didSet {
            clamp(&dotRadius, low: 0, high: 1)
            needsUpdate = true
        }
    }

    public init() {
        super.init(functionName: "polkaDot")
        title = "Polka Dot"
        properties = [Property(key: "dotRadius", title: "Dot Radius")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.dotRadius = Tools.convert(dotRadius, oldMin: 0, oldMax: 1, newMin: 0.05, newMax: 0.5)
        updateUniforms(uniforms: uniforms)
    }
}
