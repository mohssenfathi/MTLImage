//
//  TemplateFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/29/16.
//
//

import UIKit

struct TemplateUniforms: Uniforms {
    
}

public
class TemplateFilter: MTLFilter {
    
    var uniforms = TemplateUniforms()
    
    public var someProperty: Float = 0.5 {
        didSet {
            clamp(&someProperty, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "template")
        title = "Template"
        properties = [MTLProperty(key: "someProperty", title: "Some Property")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        updateUniforms(uniforms: uniforms)
    }
    
}
