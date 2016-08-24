//
//  MTLCropFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/12/16.
//
//

import UIKit

struct CropUniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
    var fit: Int = 1
}

public
class MTLCropFilter: MTLFilter {
    
    var uniforms = CropUniforms()
   
    public var fit: Bool = true {
        didSet {
            needsUpdate = true
            update()
        }
    }

    public var cropRegion: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet {
            assert(cropRegion.size.width  <= 1.0)
            assert(cropRegion.size.height <= 1.0)
            assert(cropRegion.origin.x    >= 0.0)
            assert(cropRegion.origin.y    >= 0.0)
            
            internalTexture = nil
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "crop")
        title = "Crop"
        properties = [MTLProperty(key: "cropRegion", title: "Crop Region", propertyType: .rect),
                      MTLProperty(key: "fit"       , title: "Fit"        , propertyType: .bool)]
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }

        uniforms.x = Float(cropRegion.origin.x)
        uniforms.y = Float(cropRegion.origin.y)
        uniforms.width = Float(cropRegion.size.width)
        uniforms.height = Float(cropRegion.size.height)
        uniforms.fit = fit ? 1 : 0
        
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: MemoryLayout<CropUniforms>.size, options: .cpuCacheModeWriteCombined)
    }
    
    
    func updateCroppedTexture() {

        guard let inputTexture = input?.texture else {
            return
        }
        
        let newX = Int(cropRegion.origin.x * CGFloat(inputTexture.width))
        let newY = Int(cropRegion.origin.y * CGFloat(inputTexture.height))
        let newWidth  = Int(cropRegion.size.width * CGFloat(inputTexture.width))
        let newHeight = Int(cropRegion.size.height * CGFloat(inputTexture.height))
        
        if newWidth <= 1 || newHeight <= 1 { return }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(with: .rgba8Unorm, width: newWidth, height: newHeight, mipmapped: false)
        let newTexture = device.newTexture(with: textureDescriptor)
        
        let commandBuffer = self.context.commandQueue.commandBuffer()
        let blitCommandEncoder = commandBuffer.blitCommandEncoder()
        
        blitCommandEncoder.copy(from: inputTexture,
                                           sourceSlice: 0,
                                           sourceLevel: 0,
                                           sourceOrigin: MTLOrigin(x: newX, y: newY, z: 0),
                                           sourceSize: MTLSize(width: newWidth, height: newHeight, depth: 1),
                                           to: newTexture,
                                           destinationSlice: 0,
                                           destinationLevel: 0,
                                           destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
        
        internalTexture = newTexture
    }
    
    public override var texture: MTLTexture? {
        get {
            if internalTexture == nil {
                updateCroppedTexture()
            }
            return internalTexture
        }
    }
}
