//
//  MTLHazeFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct HazeUniforms {
    var distance: Float = 0.5
    var slope: Float = 0.5;
}

public
class MTLHazeFilter: MTLFilter {
    
    var uniforms = HazeUniforms()
    
    public var distance: Float = 0.5 {
        didSet {
            clamp(&distance, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public var slope: Float = 0.5 {
        didSet {
            clamp(&distance, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "haze")
        title = "Haze"
        properties = [MTLProperty(key: "distance", title: "Distance", type: Float()),
                      MTLProperty(key: "slope"   , title: "Slope"   , type: Float())]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.distance = distance * 0.6 - 0.3
        uniforms.slope = distance * 0.6 - 0.3
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(HazeUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}