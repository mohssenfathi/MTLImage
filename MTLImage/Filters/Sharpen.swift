//
//  Sharpen.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct SharpenUniforms: Uniforms {
    var sharpness: Float = 0.0;
}

public
class Sharpen: Filter {
    var uniforms = SharpenUniforms()
    
    public var sharpness: Float = 0.0 {
        didSet {
            clamp(&sharpness, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "sharpen")
        title = "Sharpen"
        properties = [Property(key: "sharpness", title: "Sharpness")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.sharpness = sharpness * 4.0
        updateUniforms(uniforms: uniforms)
    }

}
