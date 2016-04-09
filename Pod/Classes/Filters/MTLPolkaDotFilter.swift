//
//  MTLSaturationFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct PolkaDotUniforms {
    var dotRadius: Float = 0.0
}

public
class MTLPolkaDotFilter: MTLFilter {
    
    var uniforms = PolkaDotUniforms()
    
    public var dotRadius: Float = 0.0 {
        didSet {
            clamp(&dotRadius, low: 0, high: 1)
            dirty = true
            update()
        }
    }

    public init() {
        super.init(functionName: "polkaDot")
        title = "Polka Dot"
        properties = [MTLProperty(key: "dotRadius", title: "Dot Radius", type: Float())]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.dotRadius = Tools.convert(dotRadius, oldMin: 0, oldMax: 1, newMin: 0.05, newMax: 0.5)
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(PolkaDotUniforms), options: .CPUCacheModeDefaultCache)
    }
}
