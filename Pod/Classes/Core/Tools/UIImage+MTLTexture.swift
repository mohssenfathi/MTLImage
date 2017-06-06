//
//  UIImage+MTLTexture.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

#if !(TARGET_OS_SIMULATOR)
import Metal
import MetalKit
#endif

extension UIImage {
    
    func texture(_ device: MTLDevice) -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: device)
        
        guard let cgImage = self.cgImage else {
            print("Error loading CGImage")
            return nil
        }
        
        let options = [ MTKTextureLoader.Option.SRGB : NSNumber(value: false) ]
        return try? textureLoader.newTexture(with: cgImage, options: options)
    }

//    func texture(_ device: MTLDevice) -> MTLTexture? {
//        return texture(device, flip: false, size: size)
//    }
    
    func texture(_ device: MTLDevice, flip: Bool, size: CGSize) -> MTLTexture? {
    
        var width:  Int = Int(size.width)
        var height: Int = Int(size.height)

        if width  == 0 { width  = Int(self.size.width ) }
        if height == 0 { height = Int(self.size.height) }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        let (_, _, data) = imageData(with: CGSize(width: width, height: height))
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        let texture = device.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: data!, bytesPerRow: bytesPerRow)
        
        free(data)
        
        return texture
    }
    
    func rotationAngle(_ orientation: UIImageOrientation) -> CGFloat {
        
        var angle: CGFloat = 0.0
        
        switch orientation {
        case .down : angle = 180.0; break
        case .right: angle = 90.0 ; break
        case .left : angle = 270.0; break
        default: break
        }
        
        return CGFloat.pi * angle / 180.0
    }
    
    func imageData(with size: CGSize) -> (CGContext?, CGImage?, UnsafeMutableRawPointer?) {
    
        guard let cgImage = cgImage else { return (nil, nil, nil) }
        
        var transform: CGAffineTransform = .identity
    
        switch (imageOrientation) {

        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break;
    
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2.0)
            break;
    
    
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi/2.0)
            break;
            
        default: break;
        }

        
        switch (imageOrientation) {
            
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break;
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break;
            
        default: break;
        }

//        guard let context = CGContext(data: data,
//                                width: Int(size.width), height: Int(size.height),
//                                bitsPerComponent: cgImage.bitsPerComponent,
//                                bytesPerRow: cgImage.bytesPerRow,
//                                space: cgImage.colorSpace!,
//                                bitmapInfo: cgImage.bitmapInfo.rawValue) else { return (nil, nil) }

        let width:  Int = Int(size.width)
        let height: Int = Int(size.height)
        let rawData: UnsafeMutableRawPointer = calloc(height * width * 4, MemoryLayout<Int>.size)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerCompoment = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(CGBitmapInfo.byteOrder32Little)
        // CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(CGBitmapInfo.byteOrder32Big)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerCompoment,
                                      bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
                                        return (nil, nil, nil)
        }
        
        context.concatenate(transform)
    
        
        switch (self.imageOrientation) {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return (context, context.makeImage(), rawData)
    }
}
