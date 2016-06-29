//
//  MTLBrightnessFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

struct BrightnessUniforms {
    var brightness: Float = 0.5;
}

public
class MTLBrightnessFilter: MTLFilter {

    var uniforms = BrightnessUniforms()
    
    public var brightness: Float = 0.5 {
        didSet {
            clamp(&brightness, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "brightness")
        title = "Brightness"
        properties = [MTLProperty(key: "brightness", title: "Brightness")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.brightness = brightness * 2.0 - 1.0
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(BrightnessUniforms), options: .cpuCacheModeWriteCombined)
    }

}
