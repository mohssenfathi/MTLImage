//
//  MTLNonMaximumSuppressionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

struct NonMaximumSuppressionUniforms {
    var texelWidth: Float = 0.5;
    var texelHeight: Float = 0.5;
    var lowerThreshold: Float = 0.5;
    var upperThreshold: Float = 0.5;
}

public
class MTLNonMaximumSuppressionFilter: MTLFilter {
    
    var uniforms = NonMaximumSuppressionUniforms()
    
    public var lowerThreshold: Float = 0.5 {
        didSet {
            clamp(&lowerThreshold, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var upperThreshold: Float = 0.5 {
        didSet {
            clamp(&upperThreshold, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "nonMaximumSuppression")
        title = "Non Maximum Suppression"
        properties = [MTLProperty(key: "lowerThreshold", title: "Lower Threshold"),
                      MTLProperty(key: "upperThreshold", title: "Upper Threshold")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.lowerThreshold = lowerThreshold
        uniforms.upperThreshold = upperThreshold
        uniforms.texelWidth = 1.0;
        uniforms.texelHeight = 1.0;
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(NonMaximumSuppressionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}

