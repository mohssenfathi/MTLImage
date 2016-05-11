//
//  MTLConvolutionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

public
class MTLConvolutionFilter: MTLFilter {
    
    private var convolutionMatrixTexture: MTLTexture?
    
    public var convolutionMatrix: [[Float]] = [[0.0, 0.0, 0.0],
                                               [0.0, 1.0, 0.0],
                                               [0.0, 0.0, 0.0]] {
        didSet {
            needsUpdate = true
            convolutionMatrixTexture = nil
        }
    }
    
    public init() {
        super.init(functionName: "convolution")
        title = "Convolution"
        properties = []
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if convolutionMatrixTexture == nil {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: 3, height: 3, mipmapped: false)
            convolutionMatrixTexture = device.newTextureWithDescriptor(textureDescriptor)
            
            let f = Array(convolutionMatrix.flatten())
            convolutionMatrixTexture!.replaceRegion(MTLRegionMake2D(0, 0, 3, 3), mipmapLevel: 0, withBytes: f, bytesPerRow: sizeof(Float) * 3)
        }
        commandEncoder.setTexture(convolutionMatrixTexture, atIndex: 2)
    }
    
}
