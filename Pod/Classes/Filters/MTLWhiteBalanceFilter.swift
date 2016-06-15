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
            clamp(&temperature, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var tint: Float = 0.5 {
        didSet {
            clamp(&tint, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "whiteBalance")
        title = "White Balance"
        properties = [MTLProperty(key: "temperature", title: "Temperature"),
                      MTLProperty(key: "tint"       , title: "Tint"       )]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.temperature = temperature * 2.0 - 1.0
        uniforms.tint        = tint        * 4.0 - 2.0
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(WhiteBalanceUnigforms), options: .cpuCacheModeWriteCombined)
    }
}
