//
//  Hue.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/29/16.
//
//

import UIKit

struct HueUniforms: Uniforms {
    var hue: Float = 0.0
}

public
class Hue: Filter {
    
    var uniforms = HueUniforms()
    
    public var hue: Float = 0.0 {
        didSet {
            clamp(&hue, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "hue")
        title = "Hue"
        properties = [Property(key: "hue", title: "Hue")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.hue = fmodf(hue * 360.0, 360.0) * (Float.pi / 180.0)
        updateUniforms(uniforms: uniforms)
    }
    
}
