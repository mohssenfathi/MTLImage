//
//  MTLSharpenFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct SharpenUniforms {
    var sharpness: Float = 0.5;
    var imageWidthFactor: Float = 0.0;
    var imageHeightFactor: Float = 0.0;
}

public
class MTLSharpenFilter: MTLFilter {
    var uniforms = SharpenUniforms()
    
    public var sharpness: Float = 0.5 {
        didSet {
            clamp(&sharpness, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "sharpen")
        title = "Sharpen"
        properties = [MTLProperty(key: "sharpness", title: "Sharpness")]
        update()
    }
    
    func setupFilterForSize() {
//        runSynchronously { 
        if let size = sourcePicture?.processingSize {
            uniforms.imageWidthFactor = 1.0/Float(size.width)
            uniforms.imageHeightFactor = 1.0/Float(size.height)
        }
//        }
    }
    
    override func update() {
        if self.input == nil { return }
        setupFilterForSize()
        uniforms.sharpness = sharpness * 4.0
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(SharpenUniforms), options: .CPUCacheModeDefaultCache)
    }

}