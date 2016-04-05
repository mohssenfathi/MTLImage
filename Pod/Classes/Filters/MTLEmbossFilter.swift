//
//  MTLEmbossFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

public
class MTLEmbossFilter: MTLConvolutionFilter {

    public var intensity: Float = 0.0 {
        didSet {
            dirty = true
            update()
        }
    }
    
    override init() {
        super.init()
        title = "Emboss"
        properties = [MTLProperty(key: "intensity", title: "Intensity")]
    }
    
    override func update() {
        if self.input == nil { return }
        
        let intense = intensity
        uniforms.convolutionMatrix = MTLFloat3x3( one:   MTLFloat3(one: -intense * 2.0, two: -intense, three: 0.0),
                                                  two:   MTLFloat3(one: -intense      , two: 0.0     , three: intense),
                                                  three: MTLFloat3(one: 0.0           , two:  intense, three: intense * 2.0))
        
        uniforms.texelWidth = 100.0
        uniforms.texelHeight = 100.0
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(ConvolutionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}
