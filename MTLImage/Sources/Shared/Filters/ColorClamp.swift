//
//  ColorClamp.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

import MetalKit

public
struct ColorClampUniforms: Uniforms {
    var min: float4 = float4(0, 0, 0, 0)
    var max: float4 = float4(1, 1, 1, 1)
}

public
class ColorClamp: Filter {
    var uniforms = ColorClampUniforms()
    
    @objc public var min: float4 = float4(0, 0, 0, 0) {
        didSet { needsUpdate = true }
    }
    
    @objc public var max: float4 = float4(1, 1, 1, 1) {
        didSet { needsUpdate = true }
    }
    
    public init() {
        super.init(functionName: "colorClamp")
        title = "Color Clamp"
        properties = []
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func update() {
        uniforms.min = min
        uniforms.max = max
        updateUniforms(uniforms: uniforms, size: MemoryLayout<ColorClampUniforms>.size)
    }
}
