//
//  ColorMatrix.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/20/18.
//

import Foundation
import MetalKit

public
struct ColorMatrixUniforms: Uniforms {
    var red: float4   = float4(x: 1, y: 0, z: 0, w: 0)
    var green: float4 = float4(x: 0, y: 1, z: 0, w: 0)
    var blue: float4  = float4(x: 0, y: 0, z: 1, w: 0)
    var alpha: float4 = float4(x: 0, y: 0, z: 0, w: 1)
    var bias: float4  = float4(x: 0, y: 0, z: 0, w: 0)
}

public
class ColorMatrix: Filter {

    public var uniforms = ColorMatrixUniforms()
    
    public var red: float4   = float4(x: 1, y: 0, z: 0, w: 0) { didSet { needsUpdate = true } }
    public var green: float4 = float4(x: 0, y: 1, z: 0, w: 0) { didSet { needsUpdate = true } }
    public var blue: float4  = float4(x: 0, y: 0, z: 1, w: 0) { didSet { needsUpdate = true } }
    public var alpha: float4 = float4(x: 0, y: 0, z: 0, w: 1) { didSet { needsUpdate = true } }
    public var bias: float4  = float4(x: 0, y: 0, z: 0, w: 0) { didSet { needsUpdate = true } }
    
    public init() {
        super.init(functionName: "colorMatrix")
        title = "Color Matrix"
        properties = []
        update()
    }
    
    convenience init(red: float4, green: float4, blue: float4, alpha: float4, bias: float4) {
        self.init()

        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.bias = bias
    }
    
    override public func update() {
        super.update()
        
        uniforms.red = red
        uniforms.green = green
        uniforms.blue = blue
        uniforms.alpha = alpha
        uniforms.bias = bias
        
        updateUniforms(uniforms: uniforms, size: MemoryLayout<ColorMatrixUniforms>.size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
