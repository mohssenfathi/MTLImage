//
//  GaussianBlur.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class GaussianBlur: MPS {
 
    public var sigma: Float = 0.5 {
        didSet {
            clamp(&sigma, low: 0, high: 1)
            kernel = MPSImageGaussianBlur(device: context.device, sigma: sigma * 80)
            (kernel as! MPSImageGaussianBlur).edgeMode = .clamp
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func commonInit() {
        title = "Gaussian Blur"
        properties = [Property(key: "sigma", title: "Sigma")]
        sigma = 0.5
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
