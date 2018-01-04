//
//  CVPixelBuffer-MTLTextuew.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 12/17/17.
//

import Foundation
import Metal

class PixelBufferToMTLTexture {
    
    var textureCache: CVMetalTextureCache?
    
    init(device: MTLDevice) {
        
        CVMetalTextureCacheCreate(kCFAllocatorSystemDefault, nil, device, nil, &textureCache)
    }
    
    func convert(pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer);
        let height = CVPixelBufferGetHeight(pixelBuffer);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvMetalTexture)
        
        guard let cvMetalTex = cvMetalTexture,
            let texture = CVMetalTextureGetTexture(cvMetalTex) else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return nil
        }
        
        return texture
    }
}
