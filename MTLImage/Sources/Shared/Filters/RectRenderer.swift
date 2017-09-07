//
//  RectRenderer.swift
//  PT
//
//  Created by Mohssen Fathi on 9/5/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

struct RectRendererUniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
    var lineWidth: Float = 1.0
}

public
class RectRenderer: Filter {

    public init() {
        super.init(functionName: "rectRenderer")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var uniforms = RectRendererUniforms()
    
    public var rect: CGRect = .zero {
        didSet { needsUpdate = true }
    }
    
    public var lineWidth: Float = 1.0 {
        didSet { needsUpdate = true }
    }
    
    override public func update() {
        super.update()
        
        uniforms.lineWidth = lineWidth
        uniforms.x = Float(rect.origin.x)
        uniforms.y = Float(rect.origin.y)
        uniforms.width = Float(rect.size.width)
        uniforms.height = Float(rect.size.height)
        
        uniformsBuffer = context.device.makeBuffer(bytes: &uniforms,
                                                   length: MemoryLayout<RectRendererUniforms>.size,
                                                   options: .cpuCacheModeWriteCombined)
    }
    
}
