//
//  MTLGaussianBlurFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class MTLGaussianBlurFilter: MTLMPSFilter {
 
    var sigma: Float = 0.5 {
        didSet {
            clamp(&sigma, low: 0, high: 1)
            kernel = MPSImageGaussianBlur(device: context.device, sigma: sigma * 80)
            (kernel as! MPSImageGaussianBlur).edgeMode = .clamp
            needsUpdate = true
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
        title = "Gaussian Blur"
        properties = [MTLProperty(key: "sigma", title: "Sigma")]
        sigma = 0.5
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
