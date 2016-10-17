//
//  MTLUnsharpMaskFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/19/16.
//
//

import UIKit

struct UnsharpMaskUniforms: Uniforms {
    var intensity: Float = 0.5;
}

public
class MTLUnsharpMaskFilter: MTLFilter {
    
    var uniforms = UnsharpMaskUniforms()
    let blurFilter = MTLGaussianBlurFilter()
    
    public var intensity: Float = 0.5 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var blurRadius: Float = 0.5 {
        didSet {
            blurFilter.sigma = blurRadius / 2.0
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "unsharpMask")
        title = "Unsharp Mask"
        properties = [MTLProperty(key: "blurRadius", title: "Blur Radius"),
                      MTLProperty(key: "intensity" , title: "Intensity"  ),]
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.intensity = Tools.convert(intensity, oldMin: 0, oldMid: 0.4, oldMax: 1, newMin: 0.5, newMid: 1.0, newMax: 2.3)
        updateUniforms(uniforms: uniforms)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        commandEncoder.setTexture(blurFilter.texture, at: 2)
    }
    
    public override var input: MTLInput? {
        didSet {
            if input == nil {
                blurFilter.input?.removeTarget(blurFilter)
            } else {
                input! --> blurFilter
            }
        }
    }
    
    //    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder?) {
    //        var uniforms = AdjustSaturationUniforms(saturation: saturation)
    //
    //        if uniformBuffer == nil {
    //            uniformBuffer = context.device?.newBufferWithLength(sizeofValue(uniforms), options: .cpuCacheModeWriteCombined)
    //        }
    //
    //        memcpy(uniformBuffer.contents(), withBytes: &uniforms, sizeofValue(uniforms))
    //        commandEncoder?.setBuffer(uniformBuffer, offset: 0, atIndex: 0)
    //    }
    
    
}
