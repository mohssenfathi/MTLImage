//
//  HSV.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/29/16.
//
//

import UIKit

struct HSVUniforms: Uniforms {
    var hue: Float = 0.5
    var saturation: Float = 0.5
    var vibrancy: Float = 0.5
}

public
class HSV: Filter {
    
    var uniforms = HSVUniforms()
    
    public var hue: Float = 0.5 {
        didSet {
            clamp(&hue, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var saturation: Float = 0.5 {
        didSet {
            clamp(&saturation, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var vibrancy: Float = 0.5 {
        didSet {
            clamp(&vibrancy, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "hsv")
        title = "HSV"
        properties = [Property(key: "hue"       , title: "Hue"),
                      Property(key: "saturation", title: "Saturation"),
                      Property(key: "vibrancy"  , title: "Vibrancy")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.hue = hue
        uniforms.saturation = saturation
        uniforms.vibrancy = vibrancy
        
        updateUniforms(uniforms: uniforms)
    }
    
}
