//
//  MTLOilPaintFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/19/16.
//
//

import UIKit

struct OilPaintUniforms {
    
}

public
class MTLOilPaintFilter: MTLFilter {
    
    var uniforms = OilPaintUniforms()
    
    public var brightness: Float = 0.5 {
        didSet {
            clamp(&brightness, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "oilPaint")
        title = "Oil Paint"
        properties = [MTLProperty(key: "wobble", title: "Wobble")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(OilPaintUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}
