//
//  MTLWhiteBalanceFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct WhiteBalanceUnigforms {
    var temperature: Float = 0.5;
    var tint: Float = 0.5;
}

public
class MTLWhiteBalanceFilter: MTLFilter {
    var uniforms = WhiteBalanceUnigforms()
    
    public var temperature: Float = 0.5 {
        didSet {
            dirty = true
            update()
        }
    }
    
    public var tint: Float = 0.5 {
        didSet {
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "whiteBalance")
        title = "White Balance"
        properties = [MTLProperty(key: "temperature", title: "Temperature"),
                      MTLProperty(key: "tint",        title: "Tint")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.temperature = temperature * 2.0 - 1.0
        uniforms.tint        = tint        * 4.0 - 2.0
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(WhiteBalanceUnigforms), options: .CPUCacheModeDefaultCache)
    }
}
