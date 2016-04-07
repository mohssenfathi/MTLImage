//
//  MTLLevelsFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct LevelsUniforms {
    var min: Float = 0.0
    var mid: Float = 0.5
    var max: Float = 1.0
    var minOut: Float = 0.0
    var maxOut: Float = 1.0
}

public
class MTLLevelsFilter: MTLFilter {
    var uniforms = LevelsUniforms()
    
    public var min: Float = 0.0 {
        didSet {
            clamp(&min, low: 0, high: mid)
            dirty = true
            update()
        }
    }
    
    public var mid: Float = 0.5 {
        didSet {
            clamp(&mid, low: min, high: max)
            dirty = true
            update()
        }
    }
    
    public var max: Float = 1.0 {
        didSet {
            clamp(&max, low: mid, high: 1)
            dirty = true
            update()
        }
    }
    
    public var minOut: Float = 0.0 {
        didSet {
            clamp(&minOut, low: 0, high: maxOut)
            dirty = true
            update()
        }
    }
    
    public var maxOut: Float = 1.0 {
        didSet {
            clamp(&maxOut, low: minOut, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "levels")
        title = "Levels"
        properties = [MTLProperty(key: "min", title: "Minimum"),
                      MTLProperty(key: "mid", title: "Middle"),
                      MTLProperty(key: "max", title: "Maximum"),
                      MTLProperty(key: "minOut", title: "Minimum Output"),
                      MTLProperty(key: "maxOut", title: "Maximum Output")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
//        if min > mid { min = mid }
//        if max < mid { max = mid }
//        if mid < min { mid = min }
//        if mid > max { mid = max }
        
        uniforms.min = min
        uniforms.mid = Tools.convert(mid, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: 0.0, newMid: 1.0, newMax: 10.0)
        uniforms.max = max
        uniforms.minOut = minOut
        uniforms.maxOut = maxOut
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(LevelsUniforms), options: .CPUCacheModeDefaultCache)
    }

}
