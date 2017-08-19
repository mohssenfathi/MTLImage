//
//  Voronai.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/9/16.
//
//

import UIKit

struct VoronoiUniforms: Uniforms {
    var time: Float = 0.0
    var size: Float = 0.5
    var animate: Float = 0.0
}

public
class Voronoi: Filter {
    
    var uniforms = VoronoiUniforms()
    
    public var size: Float = 0.5 {
        didSet {
            clamp(&size, low: 0.0, high: 1.0)
        }
    }
    
    public var animate: Bool = false
    
    public init() {
        super.init(functionName: "voronoi")
        title = "Voronoi"
        properties = [Property(key: "animate", title: "Animate", propertyType: .bool),
                      Property(key: "size"   , title: "Density")]
        update()
    }
    
    public override func process() {
        update()
        super.process()
        needsUpdate = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.time += 1.0/60.0
        uniforms.size = size
        uniforms.animate = animate ? 1.0 : 0.0
        
        updateUniforms(uniforms: uniforms)
    }
    
    public override var continuousUpdate: Bool {
        return true
    }
}
