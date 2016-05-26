//
//  MTLScatterFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/18/16.
//
//

import UIKit

struct ScatterUniforms {
    var radius: Float = 0.5
}

public
class MTLScatterFilter: MTLFilter {
    
    var uniforms = ScatterUniforms()
    let noiseFilter = MTLPerlinNoiseFilter()
    var noiseTexture: MTLTexture!
    
    public var radius: Float = 0.5 {
        didSet {
            clamp(&radius, low: 0, high: 1)
            noiseTexture = nil
            needsUpdate = true
            update()
        }
    }
    
    public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            noiseFilter.scale = scale/50.0
            noiseTexture = nil
            needsUpdate = true
            update()
        }
    }
    
    public var noiseImage: UIImage? {
        didSet {
            if let tex = input?.texture {
                let imageSize = CGSize(width: tex.width, height: tex.height)
                if noiseImage?.size.width > imageSize.width || noiseImage?.size.height > imageSize.height {
                    noiseImage = noiseImage?.scaleToFill(image.size)
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
        
        properties = [MTLProperty(key: "radius", title: "Radius"),
                      MTLProperty(key: "scale", title: "Scale"),
                      MTLProperty(key: "noiseImage", title: "Noise Image", propertyType: .Image)]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.radius = radius * 40
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(ScatterUniforms), options: .CPUCacheModeDefaultCache)
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
        
//        guard let outputTexture = input?.texture else {
//            noiseTexture = noiseFilter.texture
//            return
//        }
//        
//        let width  = inputTexture.width
//        let height = inputTexture.height
//        let newWidth = outputTexture.width
//        let newHeight = outputTexture.height
//        
//        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: newWidth, height: newHeight, mipmapped: false)
//        let newTexture = device.newTextureWithDescriptor(textureDescriptor)
//        
//        let commandBuffer = self.context.commandQueue.commandBuffer()
//        let blitCommandEncoder = commandBuffer.blitCommandEncoder()
//        
//        blitCommandEncoder.copyFromTexture(inputTexture,
//                                           sourceSlice: 0,
//                                           sourceLevel: 0,
//                                           sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
//                                           sourceSize: MTLSize(width: width, height: height, depth: 1),
//                                           toTexture: newTexture,
//                                           destinationSlice: 0,
//                                           destinationLevel: 0,
//                                           destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
//        
//        blitCommandEncoder.endEncoding()
//        commandBuffer.commit()
//        
//        noiseTexture = newTexture
    }
    
    func resize(image: UIImage, size: CGSize) -> UIImage? {
    
        let cgImage = image.CGImage
        
        let width = CGImageGetWidth(cgImage) / 2
        let height = CGImageGetHeight(cgImage) / 2
        let bitsPerComponent = CGImageGetBitsPerComponent(cgImage)
        let bytesPerRow = CGImageGetBytesPerRow(cgImage)
        let colorSpace = CGImageGetColorSpace(cgImage)
        let bitmapInfo = CGImageGetBitmapInfo(cgImage)
        
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        
        CGContextSetInterpolationQuality(context, .High)
        CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: CGFloat(width), height: CGFloat(height))), cgImage)
        
        let scaledImage = CGBitmapContextCreateImage(context).flatMap { UIImage(CGImage: $0) }
        
        return scaledImage
    }

    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if noiseTexture == nil {
            updateNoiseTexture()
        }
        commandEncoder.setTexture(noiseTexture, atIndex: 2)
    }
    
    public override var input: MTLInput? {
        didSet {
            noiseFilter.removeAllTargets()
            noiseFilter.input = input
            if source != nil {
                noiseFilter.process()
            }
        }
    }
    
}