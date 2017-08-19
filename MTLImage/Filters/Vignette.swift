//
//  Vignette.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct VignetteUniforms: Uniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    
    var r: Float = 1.0
    var g: Float = 1.0
    var b: Float = 1.0

    var start: Float = 0.25
    var end: Float = 0.7
}

public
class Vignette: Filter {

    var uniforms = VignetteUniforms()
    
    public var center: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            needsUpdate = true
        }
    }
    
    public var color: UIColor = UIColor.black {
        didSet {
            needsUpdate = true
        }
    }
    
    public var start: Float = 0.25 {
        didSet {
            clamp(&start, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var end: Float = 0.7 {
        didSet {
            clamp(&end, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public override func reset() {
        center = CGPoint(x: 0.5, y: 0.5)
        color = UIColor.black
        start = 0.25
        end = 0.7
    }
    
    public init() {
        super.init(functionName: "vignette")
        title = "Vignette"
        properties = [Property(key: "center", title: "Center", propertyType: .point),
                      Property(key: "color" , title: "Color" , propertyType: .color),
                      Property(key: "start" , title: "Start" ),
                      Property(key: "end"   , title: "End"   )]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public var needsUpdate: Bool {
        didSet {
            if needsUpdate == true { update() }
        }
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
        uniforms.start = start
        uniforms.end   = end
        
        updateUniforms(uniforms: uniforms)
    }
}
