//
//  UIImage+MTLTexture.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

#if !(TARGET_OS_SIMULATOR)
import Metal
#endif

extension UIImage {
    
    class func imageWithTexture(texture: MTLTexture) -> UIImage? {
        
        if texture.pixelFormat != .RGBA8Unorm { return nil }
//        assert(texture.pixelFormat != .RGBA8Unorm)
        
        let imageSize = CGSize(width: texture.width, height: texture.height)
        let width:Int = Int(imageSize.width)
        let height: Int = Int(imageSize.height)
        
        let imageByteCount: Int = width * height * 4
        let imageBytes = malloc(imageByteCount)
        let bytesPerRow = width * 4

        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(imageBytes, bytesPerRow: bytesPerRow, fromRegion: region, mipmapLevel: 0)

        let releaseDataCallback: CGDataProviderReleaseDataCallback? = { (info: UnsafeMutablePointer<Void>, data: UnsafePointer<Void>, _) -> () in
            free(info)
        }
        
        let provider = CGDataProviderCreateWithData(nil, imageBytes, imageByteCount, releaseDataCallback)
    
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue).union(.ByteOrder32Big)
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        let imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, nil, false, renderingIntent)
        
        let image = UIImage(CGImage: imageRef!, scale: 0.0, orientation: .Up)
        
//        free(imageBytes)
        
        return image;
    }
    
    func texture(device: MTLDevice) -> MTLTexture? {
        return texture(device, flip: false, size: size)
    }
    
    func texture(device: MTLDevice, flip: Bool, size: CGSize) -> MTLTexture? {
    
        let imageRef = self.CGImage

        let width:  Int = Int(size.width)
        let height: Int = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawData: UnsafeMutablePointer<Void> = calloc(height * width * 4, sizeof(Int))
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerCompoment = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).union(CGBitmapInfo.ByteOrder32Big)
        let bitmapContext = CGBitmapContextCreate(rawData, width, height, bitsPerCompoment, bytesPerRow, colorSpace, bitmapInfo.rawValue)

        if flip {
            CGContextTranslateCTM(bitmapContext, 0, CGFloat(height));
            CGContextScaleCTM(bitmapContext, 1, -1);
        }
        
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: width, height: height, mipmapped: false)
        let texture = device.newTextureWithDescriptor(textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        
        free(rawData)
        
        return texture
    }
}
