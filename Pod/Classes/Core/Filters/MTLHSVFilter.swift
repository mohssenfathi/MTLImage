//
//  MTLHSVFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/29/16.
//
//

import UIKit

struct HSVUniforms {
    var hue: Float = 0.5
    var saturation: Float = 0.5
    var vibrancy: Float = 0.5
}

public
class MTLHSVFilter: MTLFilter {
    
    var uniforms = HSVUniforms()
    
    public var hue: Float = 0.5 {
        didSet {
            clamp(&hue, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var saturation: Float = 0.5 {
        didSet {
            clamp(&saturation, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var vibrancy: Float = 0.5 {
        didSet {
            clamp(&vibrancy, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "hsv")
        title = "HSV"
        properties = [MTLProperty(key: "hue"       , title: "Hue"),
                      MTLProperty(key: "saturation", title: "Saturation"),
                      MTLProperty(key: "vibrancy"  , title: "Vibrancy")]
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
        
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(HSVUniforms), options: .cpuCacheModeWriteCombined)
    }
    
}