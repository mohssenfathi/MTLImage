//
//  Mosaic.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/6/16.
//
//

import UIKit

struct MosaicUniforms: Uniforms {
    var intensity: Float = 0.5;
}

public
class Mosaic: Filter {
    
    var uniforms = MosaicUniforms()
    
    public var intensity: Float = 0.5 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "mosaic")
        title = "Mosaic"
        properties = [Property(key: "intensity", title: "Intensity")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.intensity = intensity * 50
        updateUniforms(uniforms: uniforms)
    }
    
}
