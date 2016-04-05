//
//  MTLConvolutionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct ConvolutionUniforms {
    var convolutionMatrix: MTLFloat3x3 = MTLFloat3x3( one:   MTLFloat3(one: 0.0, two: 0.0, three: 0.0),
                                                      two:   MTLFloat3(one: 0.0, two: 1.0, three: 0.0),
                                                      three: MTLFloat3(one: 0.0, two: 0.0, three: 0.0))
    var texelWidth: Float = 0.0
    var texelHeight: Float = 0.0
}

//MTLFloat4x4(one: MTLFloat4(one: 0.0, two: 0.0, three: 0.0, four: 0.0),
//two: MTLFloat4(one: 0.0, two: 0.0, three: 0.0, four: 0.0),
//three: MTLFloat4(one: 0.0, two: 0.0, three: 0.0, four: 0.0),
//four: MTLFloat4(one: 0.0, two: 0.0, three: 0.0, four: 0.0))

public
class MTLConvolutionFilter: MTLFilter {
    
    var uniforms = ConvolutionUniforms()
    
    public var convolutionMatrix: MTLFloat3x3 = MTLFloat3x3( one:   MTLFloat3(one: -1.0, two: 0.0, three: 1.0),
                                                             two:   MTLFloat3(one: -2.0, two: 0.0, three: 2.0),
                                                             three: MTLFloat3(one: -1.0, two: 0.0, three: 1.0))  {
        didSet {
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "convolution")
        title = "Convolution"
        properties = []
        
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.convolutionMatrix = convolutionMatrix
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(ConvolutionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override public var input: MTLInput? {
        didSet {
            if originalImage != nil {
                uniforms.texelWidth = 0.01 // Float(1.0 / originalImage!.size.width)
                uniforms.texelHeight = 0.01 // Float(1.0 / originalImage!.size.height)
            }
        }
    }
}
