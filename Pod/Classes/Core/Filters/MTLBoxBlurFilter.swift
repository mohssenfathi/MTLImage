//
//  MTLBoxConvolutionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/18/16.
//
//

import UIKit
import MetalPerformanceShaders

class MTLBoxBlurFilter: MTLMPSFilter {
    
    
    var radius: Float = 0.5 {
        didSet {
            clamp(&radius, low: 0, high: 1)
            kernel = MPSImageBox(device      : context.device,
                                 kernelWidth : Tools.odd(value: Int(radius * 80.0)),
                                 kernelHeight: Tools.odd(value: Int(radius * 80.0)))
            (kernel as! MPSImageBox).edgeMode = .clamp
            needsUpdate = true
        }
    }
    
    
    init() {
        super.init(functionName: "DefaultShaders")
        commonInit()
    }
    
    override init(functionName: String) {
        super.init(functionName: "DefaultShaders")
        commonInit()
    }
    
    func commonInit() {
        kernel = MPSImageBox(device      : context.device,
                             kernelWidth : Tools.odd(value: Int(radius * 80.0)),
                             kernelHeight: Tools.odd(value: Int(radius * 80.0)))
        (kernel as! MPSImageBox).edgeMode = .clamp
        
        title = "Box Blur"
        properties = [MTLProperty(key: "radius" , title: "Radius")]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
