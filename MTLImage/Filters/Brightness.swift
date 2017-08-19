//
//  Brightness.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

struct BrightnessUniforms: Uniforms {
    var brightness: Float = 0.5;
}

public
class Brightness: Filter {

    var uniforms = BrightnessUniforms()
    
    public var brightness: Float = 0.5 {
        didSet {
            clamp(&brightness, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "brightness")
        title = "Brightness"
        properties = [Property(key: "brightness", title: "Brightness")]
//        properties = [Property(keyPath: \Brightness.brightness, title: "Brightness")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.brightness = brightness * 2.0 - 1.0
        updateUniforms(uniforms: uniforms)
    }

}
