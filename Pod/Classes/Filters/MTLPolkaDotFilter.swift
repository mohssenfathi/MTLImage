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
    var aspectRatio: Float = 0.6667
    var fractionalWidthOfPixel: Float = 0.02
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
        properties = [MTLProperty(key: "dotRadius", title: "Dot Radius")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.dotRadius = dotRadius * 0.6 + 0.3
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(PolkaDotUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override public var input: MTLInput? {
        didSet {
            if originalImage != nil {
                uniforms.aspectRatio = 1.0 / Float(originalImage!.size.width / originalImage!.size.height)
            }
        }
    }
}
