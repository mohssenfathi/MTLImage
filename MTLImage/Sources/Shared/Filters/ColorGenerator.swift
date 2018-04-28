//
//  ColorGenerator.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/18.
//

import MetalKit

public struct ColorGeneratorUniforms: Uniforms {
    var color: float4 = float4(x: 0, y: 0, z: 0, w: 1)
}

class ColorGenerator: Filter {

    var uniforms = ColorGeneratorUniforms()
    
    var color: UIColor = .black {
        didSet { needsUpdate = true }
    }
    
    init() {
        super.init(functionName: "colorGenerator")
        title = "Color Generator"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        super.update()
        if let components = color.components() {
            uniforms.color = float4(Float(components.red), Float(components.green), Float(components.blue), Float(components.alpha))
        }
        updateUniforms(uniforms: uniforms, size: MemoryLayout<ColorGeneratorUniforms>.size)
    }
}
