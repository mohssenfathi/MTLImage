//
//  TextureBuffer.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/13/16.
//
//

import UIKit

public
class Buffer: MTLFilter {

    var textureQueue = [MTLTexture]()
    
    private var maxBuffers: Int {
        return Int(bufferLength * 30)
    }
    
    public var bufferLength: Float = 0.5 {
        didSet {
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: nil)
        title = "Buffer"
        properties = [MTLProperty(key: "bufferLength", title: "Buffer Length")]  // Make Int propertyType later
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        if let texture = input?.texture {
            textureQueue.insert(texture.copy(device: context.device), at: 0)
        }
        
        if textureQueue.count > maxBuffers {
            _ = textureQueue.popLast()
        }
    }
    
    
    // TODO: set texture property to queue.last
    
    
    func texture(bytes: UnsafeMutableRawPointer) -> MTLTexture? {
        
        guard let tex = input?.texture else { return nil }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: tex.pixelFormat , width: tex.width, height: tex.height, mipmapped: false)
        
        let texture = device.makeTexture(descriptor: descriptor)
        texture.replace(region: MTLRegionMake2D(0, 0, tex.width, tex.height), mipmapLevel: 0,
                     withBytes: bytes, bytesPerRow: MemoryLayout<Float>.size * tex.width)
        
        return texture
    }
    
}

