//
//  MTLVignetteFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct VignetteUniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    
    var r: Float = 1.0
    var g: Float = 1.0
    var b: Float = 1.0

    var start: Float = 0.25
    var end: Float = 0.7
}

public
class MTLVignetteFilter: MTLFilter {

    var uniforms = VignetteUniforms()
    
    public var center: CGPoint = CGPointZero {
        didSet {
            dirty = true
            update()
        }
    }
    
    public var color: UIColor = UIColor.blackColor() {
        didSet {
            dirty = true
            update()
        }
    }
    
    public var start: Float = 0.25 {
        didSet {
            clamp(&start, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public var end: Float = 0.7 {
        didSet {
            clamp(&end, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "vignette")
        title = "Vignette"
        properties = [MTLProperty(key: "center", title: "Center", type: CGPoint()),
                      MTLProperty(key: "color" , title: "Color" , type: UIColor()),
                      MTLProperty(key: "start" , title: "Start" , type: Float()),
                      MTLProperty(key: "end"   , title: "End"   , type: Float())]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
        let components = CGColorGetComponents(color.CGColor)
        if color == UIColor.whiteColor() || color == UIColor.blackColor() {
            uniforms.r = Float(components[0])
            uniforms.g = Float(components[0])
            uniforms.b = Float(components[0])
        } else {
            uniforms.r = Float(components[0])
            uniforms.g = Float(components[1])
            uniforms.b = Float(components[2])
        }
        
//        TODO: Scale here, not in shader
        uniforms.x = Float(center.x)
        uniforms.y = Float(center.y)
        
        uniforms.start = start
        uniforms.end   = end
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(VignetteUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override public var input: MTLInput? {
        didSet {
//            if CGPointEqualToPoint(center, CGPointZero) && input?.texture != nil {
//                center = CGPointMake(CGFloat(input!.texture!.width/2), CGFloat(input!.texture!.height/2))
//            }
        }
    }
}
