//
//  Normalize.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/30/18.
//

import MetalKit

public struct NormalizeUniforms: Uniforms {
    var fromMin: float4 = float4(0.0, 0.0, 0.0, 1.0)
    var fromMax: float4 = float4(1.0, 1.0, 1.0, 1.0)
}

@available(iOS 11.0, *)
public class Normalize: Filter {

    public var fromMin: float4 = float4(0.0, 0.0, 0.0, 1.0) { didSet { needsUpdate = true } }
    public var fromMax: float4 = float4(1.0, 1.0, 1.0, 1.0) { didSet { needsUpdate = true } }
    
    var uniforms = NormalizeUniforms()
    
    override init(functionName: String?) {
        super.init(functionName: "normalize")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func update() {
        super.update()
        uniforms.fromMin = fromMin
        uniforms.fromMax = fromMax
        updateUniforms(uniforms: uniforms, size: MemoryLayout<NormalizeUniforms>.size)
    }
}
