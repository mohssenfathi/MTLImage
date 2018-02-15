//
//  ColorIsolator.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 1/5/18.
//

import Foundation
import MetalKit

struct ColorIsolatorUniforms: Uniforms {
    var color: float4 = float4(0, 0, 0, 0)
    var threshold: Float = 0.1;
}

public
class ColorIsolator: Filter {
    
    var uniforms = ColorIsolatorUniforms()
    
    @objc public var threshold: Float = 0.1 {
        didSet {
            needsUpdate = true
        }
    }
    
    @objc public var color: UIColor = .clear {
        didSet {
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "colorIsolator")
        
        title = "Color Isolator"
        
        properties = [
            Property(key: "color", title: "Color"),
            Property(key: "threshold", title: "Threshold")
        ]
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func update() {
        if self.input == nil { return }
        
        let count = color.cgColor.numberOfComponents
        if let components = color.cgColor.components {
            if count == 4 {
                uniforms.color = float4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
            } else if count == 2 {
                uniforms.color = float4(Float(components[0]), Float(components[0]), Float(components[0]), Float(components[1]))
            } else {
                uniforms.color = float4(0, 0, 0, 0)
            }
        } else {
            uniforms.color = float4(0, 0, 0, 0)
        }
        
        uniforms.threshold = threshold
        
        updateUniforms(uniforms: uniforms)
    }
    
}
