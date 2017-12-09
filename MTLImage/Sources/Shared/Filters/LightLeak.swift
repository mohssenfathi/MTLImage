//
//  LightLeak.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 11/12/17.
//


public
class LightLeak: Filter {

    struct LightLeakUniforms: Uniforms {
        
    }
    
    var uniforms = LightLeakUniforms()
    
    public init() {
        super.init(functionName: "lightLeak")
        title = "Light Leak"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func update() {
        super.update()
//        if self.input == nil { return }
//        updateUniforms(uniforms: uniforms)
    }
    
}
