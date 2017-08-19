//
//  Saturation.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct CrossHatchUniforms: Uniforms {
    var crossHatchSpacing: Float = 0.03;
    var lineWidth: Float = 0.003;
}

public
class CrossHatch: Filter {
    
    var uniforms = CrossHatchUniforms()
    
    public var crossHatchSpacing: Float = 0.5 {
        didSet {
            clamp(&crossHatchSpacing, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var lineWidth: Float = 0.5 {
        didSet {
            clamp(&lineWidth, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "crossHatch")
        title = "Cross Hatch"
        properties = [ Property(key: "crossHatchSpacing", title: "Cross Hatch Spacing"),
                       Property(key: "lineWidth"        , title: "Line Width"         )]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        
//        guard input != nil else {
//            needsUpdate = false
//            return
//        }
//        
//        guard texture != nil else {
//            needsUpdate = false
//            return
//        }
        
//        var chs = Tools.convert(crossHatchSpacing, oldMin: 0, oldMax: 1, newMin: 0.01, newMax: 0.08)

//        if uniformsBuffer != nil {
//            var singlePixelSpacing: Float!
//            if texture!.width != 0 { singlePixelSpacing = 1.0 / Float(texture!.width) }
//            else                   { singlePixelSpacing = 1.0 / 2048.0                }
//            if (chs < singlePixelSpacing) { chs = singlePixelSpacing }
//        }
        
        uniforms.crossHatchSpacing = Tools.convert(crossHatchSpacing, oldMin: 0, oldMax: 1, newMin: 20.0, newMax: 100.0)
//        uniforms.lineWidth = Tools.convert(lineWidth, oldMin: 0, oldMax: 1, newMin: 0.001, newMax: 0.008)
        uniforms.lineWidth = Tools.convert(lineWidth, oldMin: 0, oldMax: 1, newMin: 1.0, newMax: 8.0)
        updateUniforms(uniforms: uniforms)
    }    
}
