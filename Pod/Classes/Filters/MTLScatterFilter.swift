//
//  MTLScatterFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/18/16.
//
//

import UIKit

struct ScatterUniforms {
    var radius: Float = 0.5
}

public
class MTLScatterFilter: MTLFilter {
    
    var uniforms = ScatterUniforms()
    let noiseFilter = MTLPerlinNoiseFilter()
    let blurFilter = MTLGaussianBlurFilter()
    
    public var radius: Float = 0.5 {
        didSet {
            clamp(&radius, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var noise: Float = 0.5 {
        didSet {
            clamp(&noise, low: 0, high: 1)
            noiseFilter.scale = noise/50.0
            needsUpdate = true
            update()
        }
    }
    
    public var smooth: Float = 0.5 {
        didSet {
            clamp(&smooth, low: 0, high: 1)
            blurFilter.blurRadius = smooth
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "scatter")
        title = "Scatter"
        
        properties = [MTLProperty(key: "radius", title: "Radius"),
                      MTLProperty(key: "noise", title: "Noise")]
//                      MTLProperty(key: "smooth", title: "Smooth")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.radius = radius * 40
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(ScatterUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        commandEncoder.setTexture(noiseFilter.texture, atIndex: 2)
    }
    
    public override var input: MTLInput? {
        didSet {
            noiseFilter.removeAllTargets()
            noiseFilter.input = input
//            noiseFilter > blurFilter
            noiseFilter.process()
//            blurFilter.process()
        }
    }
    
}