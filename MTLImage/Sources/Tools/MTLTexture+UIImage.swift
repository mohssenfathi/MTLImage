//
//  MTLTexture+UIImage.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/11/16.
//
//

import Foundation
import Metal

extension MTLTexture {

//    func image() -> UIImage? {
//        
//        let bytesPerPixel: Int = 4
//        let imageByteCount = width * height * bytesPerPixel
//        let bytesPerRow = width * bytesPerPixel
//        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
//        
//        let region = MTLRegionMake2D(0, 0, width, height)
//        getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
//        
//        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
//        
//        let grayColorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitsPerComponent = 8
//        let context = CGContext(data: &src, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: grayColorSpace, bitmapInfo: bitmapInfo.rawValue);
//        
//        let dstImageFilter = context!.makeImage();
//        
//        return UIImage(cgImage: dstImageFilter!, scale: 0.0, orientation: UIImageOrientation.downMirrored)
//        
//    }
    
    func bytes() -> UnsafeMutableRawPointer? {

//        guard pixelFormat == .rgba8Unorm else { return nil }

        let imageByteCount: Int = width * height * 4
        guard let imageBytes = UnsafeMutableRawPointer(malloc(imageByteCount)) else { return nil }
        let bytesPerRow = width * 4
        
        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        getBytes(imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        return imageBytes
    }
    
    func image() -> UIImage? {

        guard let imageBytes = bytes() else { return nil }
        
        let bytesPerRow = width * 4
        let imageByteCount: Int = width * height * 4
        
        let provider = CGDataProvider(dataInfo: nil, data: imageBytes, size: imageByteCount) { (rawPointer, pointer, i) in
            
        }
        
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: CGBitmapInfo!
        
        if pixelFormat == .bgra8Unorm {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(.byteOrder32Little)
        }
        else if pixelFormat == .rgba8Unorm {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Big)
        }
        else { return nil }
        
        let renderingIntent = CGColorRenderingIntent.defaultIntent
        let imageRef = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: renderingIntent)
        
        let image = UIImage(cgImage: imageRef!, scale: 0.0, orientation: .up)
        
        //        free(imageBytes)
        
        return image;
    }
    
    func copy(device: MTLDevice) -> MTLTexture {
        let data = bytes()!
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        let copy = device.makeTexture(descriptor: descriptor)!
        copy.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: data, bytesPerRow: MemoryLayout<Float>.size * width)
        free(data)
        return copy
    }
    
}

