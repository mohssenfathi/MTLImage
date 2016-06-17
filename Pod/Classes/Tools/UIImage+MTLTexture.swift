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
    
    class func imageWithTexture(_ texture: MTLTexture) -> UIImage? {
        
        if texture.pixelFormat != .rgba8Unorm { return nil }
        
        let imageSize = CGSize(width: texture.width, height: texture.height)
        let width:Int = Int(imageSize.width)
        let height: Int = Int(imageSize.height)
        
        let imageByteCount: Int = width * height * 4
        let imageBytes = UnsafeMutablePointer<Void>(malloc(imageByteCount))
        let bytesPerRow = width * 4

        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(imageBytes!, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let data = NSData(bytes: imageBytes!, length: imageByteCount)
        let provider = CGDataProvider(data: data)
    
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Big)
        let renderingIntent = CGColorRenderingIntent.defaultIntent
        let imageRef = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: renderingIntent)
        
        let image = UIImage(cgImage: imageRef!, scale: 0.0, orientation: .up)
        
        free(imageBytes)
        
        return image;
    }
    
    func texture(_ device: MTLDevice) -> MTLTexture? {
        return texture(device, flip: false, size: size)
    }
    
    func texture(_ device: MTLDevice, flip: Bool, size: CGSize) -> MTLTexture? {
    
        let imageRef = self.cgImage

        var width:  Int = Int(size.width)
        var height: Int = Int(size.height)
    
        if width  == 0 { width  = Int(self.size.width ) }
        if height == 0 { height = Int(self.size.height) }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawData: UnsafeMutablePointer<Void> = calloc(height * width * 4, sizeof(Int))
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerCompoment = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(CGBitmapInfo.byteOrder32Big)
        let bitmapContext = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerCompoment, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        if flip {
            bitmapContext?.translate(x: 0, y: CGFloat(height));
            bitmapContext?.scale(x: 1, y: -1);
        }
        
        bitmapContext?.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)), image: imageRef!);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(with: .rgba8Unorm, width: width, height: height, mipmapped: false)
        let texture = device.newTexture(with: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        
        free(rawData)
        
        return texture
    }
}
