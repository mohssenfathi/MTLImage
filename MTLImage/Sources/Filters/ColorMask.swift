//
//  ColorMask.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/29/17.
//

struct ColorMaskUniforms {
    var r: Float = 0.0
    var g: Float = 0.0
    var b: Float = 0.0
    var a: Float = 0.0
    var threshold: Float = 1.0
}

public
class ColorMask: Filter {

    #if os(macOS)
    public var color: NSColor = .clear
    #else
    public var color: UIColor = .clear
    #endif
    
    public var threshold: Float = 1.0
    
    var uniforms = ColorMaskUniforms()
    
    override public var continuousUpdate: Bool {
        return true
    }
    
    public init() {
        super.init(functionName: "colorMask")
        
        title = "Color Mask"
        properties = [
            Property(key: "color", title: "Color", propertyType: .color),
            Property(key: "threshold", title: "Threshold")
        ]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        super.update()
        
        uniforms.threshold = threshold
        
        if color.cgColor.numberOfComponents == 4, let components = color.cgColor.components {
            uniforms.r = Float(components[0])
            uniforms.g = Float(components[1])
            uniforms.b = Float(components[2])
            uniforms.a = Float(components[3])
        } else {
            uniforms.r = 0.0
            uniforms.g = 0.0
            uniforms.b = 0.0
            uniforms.a = 0.0
        }
        
        uniformsBuffer = context.device.makeBuffer(bytes: &uniforms,
                                                   length: MemoryLayout<ColorMaskUniforms>.size,
                                                   options: .cpuCacheModeWriteCombined)
    }
    
}
