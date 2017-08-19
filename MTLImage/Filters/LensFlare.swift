//
//  LensFlare.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/1/16.
//
//

import UIKit

struct MTLLensFlareUniforms: Uniforms {
    var r: Float = 1.0
    var g: Float = 1.0
    var b: Float = 1.0
    
    var x: Float = 0.5
    var y: Float = 0.5
    
    var angleX: Float = 0.5
    var angleY: Float = 0.5
    
    var brightness: Float = 0.5;
    var showSun: Int = 1
}

public
class LensFlare: Filter {
    
    var uniforms = MTLLensFlareUniforms()
    
    public var color: UIColor = UIColor.white {
        didSet {
            needsUpdate = true
        }
    }
    
    public var angle: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            needsUpdate = true
        }
    }
    
    public var center: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            needsUpdate = true
        }
    }
    
    public var brightness: Float = 0.5 {
        didSet {
            clamp(&brightness, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var showSun: Bool = true {
        didSet {
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "lensFlare")
        title = "Lens Flare"
        properties = [Property(key: "color"     , title: "Color"   , propertyType: .color),
                      Property(key: "center"    , title: "Center"  , propertyType: .point),
                      Property(key: "angle"     , title: "Angle"   , propertyType: .point),
                      Property(key: "showSun"   , title: "Show Sun", propertyType: .bool ),
                      Property(key: "brightness", title: "Brightness")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        let components = color.cgColor.components
        if color == UIColor.white || color == UIColor.black {
            uniforms.r = Float((components?[0])!)
            uniforms.g = Float((components?[0])!)
            uniforms.b = Float((components?[0])!)
        } else {
            uniforms.r = Float((components?[0])!)
            uniforms.g = Float((components?[1])!)
            uniforms.b = Float((components?[2])!)
        }
        
        uniforms.x = Float(center.x)
        uniforms.y = Float(center.y)
        
        uniforms.angleX = Float(angle.x)
        uniforms.angleY = Float(angle.y)
        
        uniforms.brightness = brightness/10.0;
        uniforms.showSun = showSun ? 1 : 0
        
        updateUniforms(uniforms: uniforms)
    }
}
