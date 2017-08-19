//
//  Exposure.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

struct ExposureUniforms: Uniforms {
    var exposure: Float = 0.5;
}

public
class Exposure: Filter {
    
    var uniforms = ExposureUniforms()
    var uniformsMemory: UnsafeMutableRawPointer? = nil
    var uniformsPointer: UnsafeMutablePointer<ExposureUniforms>!
    
    public var exposure: Float = 0.5 {
        didSet {
            clamp(&exposure, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "exposure")
        title = "Exposure"
        properties = [Property(key: "exposure", title: "Exposure")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.exposure = Tools.convert(exposure, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: -1.5, newMid: 0.0, newMax: 2.0)
        updateUniforms(uniforms: uniforms)
    }

}
