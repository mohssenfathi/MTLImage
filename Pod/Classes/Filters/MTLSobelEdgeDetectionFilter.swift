//
//  MTLSobelEdgeDetectionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct SobelEdgeDetectionUniforms {
    var edgeStrength: Float = 0.5;
}

public
class MTLSobelEdgeDetectionFilter: MTLFilter {
    
    var uniforms = SobelEdgeDetectionUniforms()
    
    public var edgeStrength: Float = 0.0 {
        didSet {
            clamp(&edgeStrength, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "sobelEdgeDetection")
        title = "Sobel Edge Detection"
        properties = [MTLProperty(key: "edgeStrength", title: "Edge Strength")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.edgeStrength = edgeStrength * 3.0 + 0.2
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(SobelEdgeDetectionUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}

