//
//  MTLWatercolorFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/20/16.
//
//

import UIKit

struct WatercolorUniforms {
    
}

public
class MTLWatercolorFilter: MTLFilter {
    
    var uniforms = WatercolorUniforms()
    
    public init() {
        super.init(functionName: "watercolor")
        title = "Watercolor"
        properties = []
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(WatercolorUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}