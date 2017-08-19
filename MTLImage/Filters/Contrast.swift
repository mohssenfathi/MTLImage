//
//  Contrast.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct ContrastUniforms: Uniforms {
    var contrast: Float = 0.5;
}

public
class Contrast: Filter {
    var uniforms = ContrastUniforms()
    
    public var contrast: Float = 0.5 {
        didSet {
            clamp(&contrast, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "contrast")
        title = "Contrast"
        properties = [Property(key: "contrast", title: "Contrast")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if input == nil { return }
        uniforms.contrast = Tools.convert(contrast, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: 0.0, newMid: 1.0, newMax: 4.0)
        updateUniforms(uniforms: uniforms)
    }
}
