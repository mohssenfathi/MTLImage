//
//  MTLDigitRecognzier.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/23/16.
//
//

import UIKit
import  MetalPerformanceShaders

public
class MTLDigitRecognzier: MTLCNNFilter {
    
    var image1, image2, image3, image4, image5, image6, image7, image8: MPSTemporaryImage!
    var conv1, conv2, conv3, conv4: MPSCNNConvolution!
    var fc1: MPSCNNFullyConnected!
    var pool: MPSCNNPoolingMax!
    
    public init() {
        super.init(functionName: "")
        
        title = "Digit Recognizer"
        properties = []
        
        setup()
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let conv1Desc = MPSCNNConvolutionDescriptor(kernelWidth: 5, kernelHeight: 5, inputFeatureChannels: 4, outputFeatureChannels: 4, neuronFilter: nil)
        conv1 = MPSCNNConvolution(device: context.device, convolutionDescriptor: conv1Desc, kernelWeights: weights, biasTerms: biases, flags: .none)
    
    }
    
    override func update() {
        if input?.texture != nil {
            inputImage = MPSImage(texture: input!.texture!)
        }
    }
    
    override func configureCommandBuffer(commandBuffer: MTLCommandBuffer) {
        
        guard let inputImage = inputImage else { return }
        
        if outputImage == nil {
            if let texture = input?.texture {
                let outputImageDesc = MPSImageDescriptor(channelFormat: .unorm8, width: texture.width, height: texture.height, featureChannels: 4)
                outputImage = MPSImage(device: context.device, imageDescriptor: outputImageDesc)
            } else {
                return
            }
        }
        
        // Convolution 1
        let image1Desc = MPSImageDescriptor(channelFormat: .float16, width: inputImage.width, height: inputImage.height, featureChannels: 4)
        image1 = MPSTemporaryImage(for: commandBuffer, imageDescriptor: image1Desc)
        conv1.encode(to: commandBuffer, sourceImage: inputImage, destinationImage: outputImage!)
        
        
//        // Fully Connected 1
//        if fc1 == nil {
//            let fc1Desc = MPSCNNConvolutionDescriptor(kernelWidth: texture!.width, kernelHeight: texture!.height, inputFeatureChannels: 4, outputFeatureChannels: 4, neuronFilter: nil)
//            fc1 = MPSCNNFullyConnected(device: context.device, convolutionDescriptor: fc1Desc, kernelWeights: weights, biasTerms: biases, flags: .none)
//        }
//        fc1.encode(to: commandBuffer, sourceImage: image1, destinationImage: outputImage!)
    }
    
    
    let weights: [Float] = [1.04732, 1.007706, 1.00936199, 1.030912, 1.032012, 1.04732, 1.007706, 1.00936199, 1.030912]
    let biases : [Float] = [0.030476, 0.199366, 0.181361]
    
}
