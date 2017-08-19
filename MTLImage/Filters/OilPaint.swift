//
//  OilPaint.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/19/16.
//
//

import UIKit

struct OilPaintUniforms: Uniforms {
    
}

public
class OilPaint: Filter {
    
    var uniforms = OilPaintUniforms()
    
    public var brightness: Float = 0.5 {
        didSet {
            clamp(&brightness, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "oilPaint")
        title = "Oil Paint"
        properties = [Property(key: "wobble", title: "Wobble")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        updateUniforms(uniforms: uniforms)
    }
    
}
