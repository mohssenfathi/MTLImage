//
//  MTLSaturationFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct GaussianBlurUniforms {
    var blurRadius: Float = 1.0
    var sigma: Float = 0.5
    
    var texelWidthOffset: Float = 1.0
    var texelHeightOffset: Float = 1.0
} 

public
class MTLGaussianBlurFilter: MTLFilter {
    
    var uniforms = GaussianBlurUniforms()
    var blurWeightTexture: MTLTexture!
    var jobIndex: UInt64 = 0
    
    public var blurRadius: Float = 0.0 {
        willSet {
            if round(newValue) != blurRadius {
                blurRadius = round(newValue)
                dirty = true
                blurWeightTexture = nil
                update()
            }
        }
    }
    
    public var sigma: Float = 0.0 {
        didSet {
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "gaussianBlur")
        title = "Gaussian Blur"
        properties = [ MTLProperty(key: "blurRadius", title: "Blur Radius"),
                       MTLProperty(key: "sigma"     , title: "Sigma") ]
    }
    
    override func update() {
//        if self.input == nil { return }
//        
////        setupFilterForSize()
//        
//        jobIndex = jobIndex + 1
//        let currentJobIndex: UInt64 = jobIndex;
//        
//        dispatch_async(context.processingQueue) {
//        
//            self.uniforms.blurRadius = Tools.convert(self.blurRadius, oldMin: 0, oldMax: 1, newMin: 1, newMax: 30)
//            self.uniforms.sigma = Tools.convert(self.sigma, oldMin: 0, oldMax: 1, newMin: 0.5, newMax: 15)
            self.uniforms.blurRadius = 1.0
            self.uniforms.sigma = 0.5;
            self.uniformsBuffer = self.device.newBufferWithBytes(&self.uniforms, length: sizeof(GaussianBlurUniforms), options: .CPUCacheModeDefaultCache)
            
            if self.blurWeightTexture == nil {
                self.generateBlurRadius()
                self.secondaryTexture = self.blurWeightTexture
            }
//        }
    }
    
//    func gpuImageBlurValues() {
//        
//        var calculatedSampleRadius = 0.0
//        if blurRadius >= 1 {
//                let minimumWeightToFindEdgeOfSamplingArea: Float = 1.0 / 256.0
//                calculatedSampleRadius = floor(sqrt(-2.0 * pow(Double(blurRadius), 2.0) *
//                                         log(Double(minimumWeightToFindEdgeOfSamplingArea) *
//                                         sqrt(2.0 * M_PI * pow(Double(blurRadius), 2.0))) ))
//                calculatedSampleRadius += calculatedSampleRadius % 2
//        }
//            
//     
//        
//        var standardGaussianWeights = [Float](count: Int(blurRadius + 1), repeatedValue: 0.0)
//        var sumOfWeights: Float = 0.0
//        
//        for currentGaussianWeightIndex in 0 ..< Int(blurRadius + 1) {
//            standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * Float(M_PI) * pow(sigma, 2.0))) * exp(-pow(Float(currentGaussianWeightIndex), 2.0) / (2.0 * pow(sigma, 2.0)))
//        
//            if (currentGaussianWeightIndex == 0) {
//                sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
//            }
//            else {
//                sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
//            }
//        }
//        
//        
//        // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
//        for currentGaussianWeightIndex in 0 ..< Int(blurRadius + 1) {
//            standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
//        }
//        
//        // From these weights we calculate the offsets to read interpolated values from
//        var numberOfOptimizedOffsets: Int = Int(min(blurRadius / 2 + (blurRadius % 2), 7))
//        var optimizedGaussianOffsets = [Float](count: numberOfOptimizedOffsets, repeatedValue: 0.0)
//        
//        for currentOptimizedOffset in 0 ..< numberOfOptimizedOffsets {
//            let firstWeight  = standardGaussianWeights[currentOptimizedOffset * 2 + 1];
//            let secondWeight = standardGaussianWeights[currentOptimizedOffset * 2 + 2];
//            
//            let optimizedWeight = firstWeight + secondWeight;
//            let a = firstWeight * Float(currentOptimizedOffset * 2 + 1)
//            let b = secondWeight * Float(currentOptimizedOffset * 2 + 2)
//            
//            optimizedGaussianOffsets[currentOptimizedOffset] = (a + b) / optimizedWeight;
//        }
//        
//        
//        let blurCoordinates
//        let weights = [Float]()
//        for currentOptimizedOffset in 0 ..< numberOfOptimizedOffsets {
//            
//            weights.append(<#T##newElement: Float##Float#>)
//            
//            blurCoordinates[%lu] = inputTextureCoordinate.xy + singleStepOffset * %f;\n\
//            blurCoordinates[%lu] = inputTextureCoordinate.xy - singleStepOffset * %f;\n", (unsigned long)((currentOptimizedOffset * 2) + 1), optimizedGaussianOffsets[currentOptimizedOffset], (unsigned long)((currentOptimizedOffset * 2) + 2), optimizedGaussianOffsets[currentOptimizedOffset]];
//        }
//        
//
//    }
    

    func generateBlurRadius() {
        var radius: Float = Tools.convert(blurRadius, oldMin: 0, oldMax: 1, newMin: 1, newMax: 30)
        var sig: Float = Tools.convert(sigma, oldMin: 0, oldMax: 1, newMin: 0.5, newMax: 15)
        let size: Int = Int((radius * 2) + 1)
        
        var delta: Float = 0.0
        var expScale: Float = 0.0
        
        if radius > 0 {
            delta = (radius * 2) / Float(size - 1)
            expScale = -1 / (2 * sig * sig);
        }
    
//        var weights = UnsafeMutablePointer<Float>(malloc(sizeof(Float) * size * size))
        
        var weights = [Float](count: size * size, repeatedValue: 0)
        var weightSum: Float = 0.0
        var y = -radius
        
        for j in 0 ..< size {
            var x = -radius
            
            for i in 0 ..< size {
                let weight = expf(((x * x + y * y) * expScale))
                weights[j * size + i] = weight
                weightSum += weight
                x += delta
            }
            
            y += delta
        }

        let weightScale = 1.0 / weightSum
        
        for j in 0 ..< size {
            for i in 0 ..< size {
                weights[j * size + i] *= weightScale;
            }
        }
    
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: size, mipmapped: false)
        
        blurWeightTexture = device.newTextureWithDescriptor(textureDescriptor)
        blurWeightTexture.replaceRegion(MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0, withBytes: weights, bytesPerRow: sizeof(Float)*size)
        
    }

    override public var input: MTLInput? {
        didSet {
            generateBlurRadius()
            self.secondaryTexture = self.blurWeightTexture
            update()
        }
    }

    
    func setupFilterForSize() {
        if let size = sourcePicture?.processingSize {
            uniforms.texelWidthOffset = 1.0/Float(size.width)
            uniforms.texelHeightOffset = 1.0/Float(size.height)
        }
        
//        if (self.blurRadiusAsFractionOfImageWidth > 0)
//        {
//            self.blurRadiusInPixels = filterFrameSize.width * self.blurRadiusAsFractionOfImageWidth;
//        }
//        else
//        {
//            self.blurRadiusInPixels = filterFrameSize.height * self.blurRadiusAsFractionOfImageHeight;
//        }
    }
    
    
}
