//
//  CVPixelBuffer-MTLTextuew.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 12/17/17.
//

import Foundation
import Metal
import ARKit

class PixelBufferToMTLTexture {
    
    var textureCache: CVMetalTextureCache?
    
    init(device: MTLDevice) {
        CVMetalTextureCacheCreate(kCFAllocatorSystemDefault, nil, device, nil, &textureCache)
    }
    
    func convert(pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }
        
        var cvMetalTexture : CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer);
        let height = CVPixelBufferGetHeight(pixelBuffer);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, pixelFormat, width, height, 0, &cvMetalTexture)
        
        guard let cvMetalTex = cvMetalTexture,
            let texture = CVMetalTextureGetTexture(cvMetalTex) else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return nil
        }
        
        return texture
    }
}

@available(iOS 11.0, *)
class ARFrameToMTLTexture {
    
    var textureCache: CVMetalTextureCache?
    var transform: CGAffineTransform = .identity
    
    init(device: MTLDevice) {
        CVMetalTextureCacheCreate(kCFAllocatorSystemDefault, nil, device, nil, &textureCache)
    }
    
    func convert(frame: ARFrame) -> MTLTexture? {
        
        let pixelBuffer = frame.capturedImage
        
        guard let Y = texture(from: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0),
            let CbCr = texture(from: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1) else {
                return nil
        }
        
        yCbCrToRGB.Y = Y
        yCbCrToRGB.CbCr = CbCr
        yCbCrToRGB.transform = transform
        
        yCbCrToRGB.update()
        yCbCrToRGB.process()
        
        return yCbCrToRGB.texture
    }
    
    
    func texture(from pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        
        guard let textureCache = textureCache, CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return nil
        }
        
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
    
    private let yCbCrToRGB = YCbCrToRGB()
}

@available(iOS 11.0, *)
class ARFrameTextureGenerator {
 
    var textureCache: CVMetalTextureCache?
    
    init(device: MTLDevice) {
        CVMetalTextureCacheCreate(kCFAllocatorSystemDefault, nil, device, nil, &textureCache)
    }
    
    func textures(from frame: ARFrame) -> (MTLTexture, MTLTexture)? {
        let pixelBuffer = frame.capturedImage
        
        guard let Y = texture(from: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0),
            let CbCr = texture(from: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1) else {
                return nil
        }
        
        return (Y, CbCr)
    }
    
    func texture(from pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        
        guard let textureCache = textureCache, CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return nil
        }
        
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
}
