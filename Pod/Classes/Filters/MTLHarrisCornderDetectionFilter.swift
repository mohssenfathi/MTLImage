//
//  MTLHarrisCornderDetectionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

struct HarrisCornderDetectionUniforms {
    var sensitivity: Float = 0.5;
}

public
class MTLHarrisCornderDetectionFilter: MTLFilter {
    
    var uniforms = HarrisCornderDetectionUniforms()
    let blur = MTLGaussianBlurFilter()
    let nonMaximumSuppression = MTLNonMaximumSuppressionFilter()
    
    public var blurRadius: Float = 0.5 {
        didSet {
            clamp(&blurRadius, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var sensitivity: Float = 0.5 {
        didSet {
            clamp(&sensitivity, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var threshold: Float = 0.5 {
        didSet {
            clamp(&threshold, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "harrisCornerDetection")
        title = "Harris Corner Detection"
        properties = [MTLProperty(key: "blurRadius" , title: "Blur Radius"),
                      MTLProperty(key: "sensitivity", title: "Sensitivity"),
                      MTLProperty(key: "threshold"  , title: "Threshold"  )]
        
        blur.addTarget(self)
        self.addTarget(nonMaximumSuppression)
        internalInput = blur
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        blur.blurRadius = blurRadius

        uniforms.sensitivity = sensitivity
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(HarrisCornderDetectionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    public override func process() {
        super.process()
        blur.process()
    }
    
    public override var texture: MTLTexture? {
        get {
            return nonMaximumSuppression.texture
        }
    }
    
    public override func addTarget(target: MTLOutput) {
        if target.identifier == nonMaximumSuppression.identifier {
            super.addTarget(target)
            return
        }
        
        nonMaximumSuppression.addTarget(target)
    }
    
    public override var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            if newValue?.identifier != blur.identifier {
                blur.input = newValue
                setupPipeline()
                update()
            }
        }
    }
}

