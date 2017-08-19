//
//  HighlightShadow.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/29/16.
//
//

import UIKit

struct HighlightShadowUniforms: Uniforms {
    var highlights: Float = 1.0
    var shadows   : Float = 0.0
}

public
class HighlightShadow: Filter {
    
    var uniforms = HighlightShadowUniforms()
    
    public var highlights: Float = 1.0 {
        didSet {
            clamp(&highlights, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var shadows: Float = 0.0 {
        didSet {
            clamp(&shadows, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "highlightShadow")
        title = "Highlight/Shadow"
        properties = [Property(key: "highlights", title: "Highlights"),
                      Property(key: "shadows"   , title: "Shadows")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.highlights = highlights
        uniforms.shadows = shadows
        updateUniforms(uniforms: uniforms)
    }
    
}
