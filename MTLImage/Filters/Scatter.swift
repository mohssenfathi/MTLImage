//
//  Scatter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/18/16.
//
//

import UIKit

struct ScatterUniforms: Uniforms {
    var radius: Float = 0.5
}

public
class Scatter: Filter {
    
    var uniforms = ScatterUniforms()
    let noiseFilter = PerlinNoise()
    var noiseTexture: MTLTexture!
    
    public var radius: Float = 0.5 {
        didSet {
            clamp(&radius, low: 0, high: 1)
            noiseTexture = nil
            needsUpdate = true
        }
    }
    
    public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            noiseFilter.scale = scale/50.0
            noiseTexture = nil
            needsUpdate = true
        }
    }
    
    public var noiseImage: UIImage? {
        didSet {
            
            if let tex = input?.texture {
                let imageSize = CGSize(width: tex.width, height: tex.height)
                if noiseImage?.size.width != imageSize.width && noiseImage?.size.height != imageSize.height {
                    let scaledImage = noiseImage?.scaleToFill(imageSize)  // Only calls itself once
                    noiseImage = scaledImage
                    return
                }
            }
            
            noiseTexture = nil
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "scatter")
        title = "Scatter"
        
        properties = [Property(key: "radius", title: "Radius"),
                      Property(key: "scale", title: "Scale"),
                      Property(key: "noiseImage", title: "Noise Image", propertyType: .image)]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.radius = radius * 40
        updateUniforms(uniforms: uniforms)
    }
    
    func updateNoiseTexture() {
        
        if noiseImage == nil {
            noiseTexture = noiseFilter.texture
            return
        }
        
        guard let inputTexture = input?.texture else { //noiseImage?.texture(device) else {
            noiseTexture = noiseFilter.texture
            return
        }

        let inputSize = CGSize(width: inputTexture.width, height: inputTexture.height)
        if noiseImage?.size != inputSize {
            noiseImage = resize(noiseImage!, size: inputSize)
        }
        
        noiseTexture = noiseImage?.texture(device)
    }
    
    func resize(_ image: UIImage, size: CGSize) -> UIImage? {
    
        let cgImage = image.cgImage
        
        let width = (cgImage?.width)! / 2
        let height = (cgImage?.height)! / 2
        let bitsPerComponent = cgImage?.bitsPerComponent
        let bytesPerRow = cgImage?.bytesPerRow
        let colorSpace = cgImage?.colorSpace
        let bitmapInfo = cgImage?.bitmapInfo
        
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent!, bytesPerRow: bytesPerRow!, space: colorSpace!, bitmapInfo: (bitmapInfo?.rawValue)!)
        
        context!.interpolationQuality = .high
        context?.draw(image.cgImage!, in: CGRect(origin: CGPoint.zero, size: CGSize(width: CGFloat(width), height: CGFloat(height))))
        
        let scaledImage = context?.makeImage().flatMap { UIImage(cgImage: $0) }
        
        return scaledImage
    }

    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        if noiseTexture == nil {
            updateNoiseTexture()
        }
        commandEncoder.setTexture(noiseTexture, index: 2)
    }
    
    public override var input: Input? {
        didSet {
            noiseFilter.removeAllTargets()
            noiseFilter.input = input
            if source != nil {
                noiseFilter.process()
            }
        }
    }
    
}
