//
//  MTLBlendFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/17/16.
//
//

import UIKit

struct BlendUniforms {
    var mix: Float = 0.5
    var blandMode: Int = 0
}

public
class MTLBlendFilter: MTLFilter {
    
    var uniforms = BlendUniforms()
    
    var mix: Float = 0.5 {
        didSet {
            clamp(&mix, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    var blendMode = 0 {
        didSet {
            clamp(&blendMode, low: 0, high: 7)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "blend")
        title = "Blend"
        uniforms.mix = mix
        
        let blendModeProperty = MTLProperty(key: "blendMode", title: "Blend Mode", type: Int(), propertyType: .Selection)
        blendModeProperty.selectionItems = [0 : "Normal", 1 : "Overlay", 2 : "Lighten", 3 : "Darken"]
        
        properties = [MTLProperty(key: "mix", title: "Mix"), blendModeProperty]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.mix = mix
        uniforms.blandMode = blendMode
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(BlendUniforms), options: .CPUCacheModeDefaultCache)
    }
 
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if internalInputs.count > 1 {
            commandEncoder.setTexture(internalInputs[1].texture, atIndex: 2)
        }
    }
}
