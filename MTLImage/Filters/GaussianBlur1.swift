//
//  Saturation.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

struct GaussianBlurUniforms {
    var blurRadius: Float = 1.0
    var sigma: Float = 0.5
} 

public
class GaussianBlur1: Filter {
    
    var uniforms = GaussianBlurUniforms()
    var blurWeightTexture: MTLTexture!
    
    public var blurRadius: Float = 0.0 {
        didSet {
//            if round(newValue) != blurRadius {
                clamp(&blurRadius, low: 0, high: 1)
                needsUpdate = true
                blurWeightTexture = nil
                update()
//            }
        }
    }
    
    public var sigma: Float = 0.0 {
        didSet {
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "gaussianBlur")
        title = "Gaussian Blur"
        properties = [ Property(key: "blurRadius", title: "Blur Radius"),
                       Property(key: "sigma"     , title: "Sigma"      )]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        super.update()
    
        self.uniforms.blurRadius = Tools.convert(self.blurRadius, oldMin: 0, oldMax: 1, newMin: 0, newMax: 25)
        self.uniforms.sigma = self.uniforms.blurRadius/2.0
//            self.uniforms.sigma = Tools.convert(self.sigma, oldMin: 0, oldMax: 1, newMin: 0.5, newMax: 15)
//            self.uniforms.blurRadius = 1.0
//            self.uniforms.sigma = 0.5;
        self.uniformsBuffer = self.device.makeBuffer(bytes: &self.uniforms, length: MemoryLayout<GaussianBlurUniforms>.size, options: .cpuCacheModeWriteCombined)
    }
    

    func generateBlurRadius() {
        let radius: Float = self.uniforms.blurRadius
        let sig: Float = self.uniforms.sigma
        
        if radius.isNaN || sig.isNaN { return }
        
        let size = Int(roundf(radius) * 2 + 1)
        
        var delta: Float = 0.0
        var expScale: Float = 0.0
        
        if radius > 0 {
            delta = (radius * 2) / Float(size - 1)
            expScale = -1 / (2 * sig * sig);
        }
    
//        var weights = UnsafeMutablePointer<Float>(malloc(sizeof(Float) * size * size))
        var weights = [Float](repeating: 0, count: size * size)
        
//        var weights = [[Float]]()
//        for i in 0 ..< size {
//            weights.append([Float](count: size, repeatedValue: 0.0))
//        }
        
        var weightSum: Float = 0.0
        var y = -radius
        
        for j in 0 ..< size {
            var x = -radius
            
            for i in 0 ..< size {
                let weight = expf(((x * x + y * y) * expScale))
//                weights[i][j] = weight
                weights[j * size + i] = weight
                weightSum += weight
                x += delta
            }
            
            y += delta
        }

        let weightScale = 1.0 / weightSum
        
        for j in 0 ..< size {
            for i in 0 ..< size {
//                weights[i][j] *= weightScale
                weights[j * size + i] *= weightScale
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: size, height: size, mipmapped: false)
        self.blurWeightTexture = self.device.makeTexture(descriptor: textureDescriptor)
        self.blurWeightTexture.replace(region: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0, withBytes: weights, bytesPerRow: MemoryLayout<Float>.size * size)
    }

    override public var input: Input? {
        didSet {
            update()
        }
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        if blurWeightTexture == nil {
            generateBlurRadius()
        }
        commandEncoder.setTexture(blurWeightTexture, index: 2)
    }
    
}
