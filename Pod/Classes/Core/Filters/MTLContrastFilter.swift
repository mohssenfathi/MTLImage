//
//  MTLContrastFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct ContrastUniforms {
    var contrast: Float = 0.5;
}

public
class MTLContrastFilter: MTLFilter {
    var uniforms = ContrastUniforms()
    
    public var contrast: Float = 0.5 {
        didSet {
            clamp(&contrast, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "contrast")
        title = "Contrast"
        properties = [MTLProperty(key: "contrast", title: "Contrast")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if input == nil { return }
        uniforms.contrast = Tools.convert(contrast, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: 0.0, newMid: 1.0, newMax: 4.0)
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: MemoryLayout<ContrastUniforms>.size, options: .cpuCacheModeWriteCombined)
    }
}
