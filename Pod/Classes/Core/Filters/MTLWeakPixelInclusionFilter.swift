//
//  MTLWeakPixelInclusionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

struct WeakPixelInclusionUniforms {
    
}

public
class MTLWeakPixelInclusionFilter: MTLFilter {
    
    var uniforms = WeakPixelInclusionUniforms()
    
    public init() {
        super.init(functionName: "weakPixelInclusion")
        title = "Weak Pixel Inclusion"
        properties = []
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(WeakPixelInclusionUniforms), options: .cpuCacheModeWriteCombined)
    }
    
}