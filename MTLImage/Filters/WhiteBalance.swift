//
//  WhiteBalance.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

struct WhiteBalanceUniforms: Uniforms {
    var temperature: Float = 0.5;
    var tint: Float = 0.5;
}

public
class WhiteBalance: Filter {
    
    var uniforms = WhiteBalanceUniforms()
    
    public var temperature: Float = 0.5 {
        didSet {
            clamp(&temperature, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var tint: Float = 0.5 {
        didSet {
            clamp(&tint, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "whiteBalance")
        title = "White Balance"
        properties = [Property(key: "temperature", title: "Temperature"),
                      Property(key: "tint"       , title: "Tint"       )]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.temperature = temperature * 2.0 - 1.0
        uniforms.tint        = tint        * 4.0 - 2.0
                updateUniforms(uniforms: uniforms)
    }
}
