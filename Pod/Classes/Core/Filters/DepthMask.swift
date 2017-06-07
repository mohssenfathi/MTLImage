//
//  DepthMask.swift
//  MTLImage-iOS10.0
//
//  Created by Mohssen Fathi on 6/6/17.
//

struct DepthMaskUniforms: Uniforms {
    var brightness: Float = 0.5;
}

public
class DepthMask: MTLFilter {
    
    var uniforms = DepthMaskUniforms()
    
    public init() {
        super.init(functionName: "depthMask")
        title = "Depth Mask"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        updateUniforms(uniforms: uniforms)
    }
    
}

