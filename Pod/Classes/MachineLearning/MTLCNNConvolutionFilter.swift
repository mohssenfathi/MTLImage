//
//  MTLCNNConvolutionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/20/16.
//
//

import UIKit
import  MetalPerformanceShaders

class MTLCNNConvolutionFilter: MTLCNNFilter {
    
    init() {
        super.init(functionName: "DefaultShaders")
        commonInit()
    }
    
    override init(functionName: String) {
        super.init(functionName: "DefaultShaders")
        commonInit()
    }
    
    func commonInit() {
        let descriptor = MPSCNNConvolutionDescriptor(kernelWidth: 3, kernelHeight: 3, inputFeatureChannels: 1, outputFeatureChannels: 1, neuronFilter: nil)
//        kernel = MPSCNNConvolution(device: context.device, convolutionDescriptor: descriptor, kernelWeights: <#T##UnsafePointer<Float>#>, biasTerms: <#T##UnsafePointer<Float>?#>, flags: .none)
        
        title = "Convolution"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
