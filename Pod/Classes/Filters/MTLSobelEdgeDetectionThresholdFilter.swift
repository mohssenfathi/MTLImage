//
//  MTLSobelEdgeDetectionThresholdFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/9/16.
//
//

import UIKit


struct SobelEdgeDetectionThresholdUniforms {
    var threshold: Float = 0.5;
}

public
class MTLSobelEdgeDetectionThresholdFilter: MTLFilter {
    
    var uniforms = SobelEdgeDetectionThresholdUniforms()
    let sobelEdgeDetectionFilter = MTLSobelEdgeDetectionFilter()
    
    public var threshold: Float = 0.5 {
        didSet {
            clamp(&threshold, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var edgeStrength: Float = 0.0 {
        didSet {
            sobelEdgeDetectionFilter.edgeStrength = edgeStrength
            update()
        }
    }
    
    public init() {
        super.init(functionName: "sobelEdgeDetectionThreshold")
        title = "Sobel Edge Detection Threshold"
        properties = [MTLProperty(key: "threshold", title: "Threshold"),
                      MTLProperty(key: "edgeStrength", title: "Edge Strength")]
        
        sobelEdgeDetectionFilter.addTarget(self)
        internalInput = sobelEdgeDetectionFilter
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.threshold = threshold
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(SobelEdgeDetectionThresholdUniforms), options: .cpuCacheModeWriteCombined)
    }
    
    public override func process() {
        super.process()
        sobelEdgeDetectionFilter.process()
    }
    
    public override var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            if newValue?.identifier != sobelEdgeDetectionFilter.identifier {
                sobelEdgeDetectionFilter.input = newValue
                setupPipeline()
                update()
            }
        }
    }
}
