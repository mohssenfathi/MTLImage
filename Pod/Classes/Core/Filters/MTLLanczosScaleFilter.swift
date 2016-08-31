//
//  MTLLanczosScaleFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class MTLLanczosScaleFilter: MTLMPSFilter {
    
    var scaleTransform: MPSScaleTransform = MPSScaleTransform(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    var transformPointer: UnsafePointer<MPSScaleTransform>!
    
    var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    init() {
        super.init(functionName: "EmptyShader")
        commonInit()
    }
    
    override init(functionName: String) {
        super.init(functionName: "EmptyShader")
        commonInit()
    }
    
    func commonInit() {
        
        title = "Lanczos Scale"
        properties = [MTLProperty(key: "scale", title: "Scale")] //,
//                      MTLProperty(key: "width", title: "Width"),
//                      MTLProperty(key: "height", title: "Height")]
        
        transformPointer = withUnsafePointer(to: &scaleTransform, { (pointer: UnsafePointer<MPSScaleTransform>) -> UnsafePointer<MPSScaleTransform>! in
            return pointer
        })
        
        kernel = MPSImageLanczosScale(device: context.device)
        
        update()
    }
    
    override func update() {
        let s = Double(1 + scale * 10.0)
        
        (kernel as! MPSImageLanczosScale).scaleTransform = transformPointer
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
