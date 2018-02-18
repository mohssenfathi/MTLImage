
//
//  Helpers.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Metal
import MetalKit
import AVFoundation
import ARKit

extension CVPixelBuffer {
    
    func mtlTexture(device: MTLDevice) -> MTLTexture? {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = width
        descriptor.height = height
        descriptor.pixelFormat = .bgra8Unorm
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.init(rawValue: 0))
        
        guard let bytes = CVPixelBufferGetBaseAddress(self) else {
            CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.init(rawValue: 0))
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        
        texture.replace(
            region: MTLRegion(origin: MTLOriginMake(0, 0, 0), size: MTLSize(width: width, height: height, depth: 1)),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: bytesPerRow
        )
        
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.init(rawValue: 0))
        
        return texture
    }
    
}


// MARK: - MTLTexture
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

    var pixelBuffer: CVPixelBuffer? {
        
        guard let bytes = bytes() else {
            return nil
        }
        
        var pb: CVPixelBuffer? = nil
        
        let attributes = [
            kCVPixelBufferIOSurfacePropertiesKey : [:]
            ] as CFDictionary
        
        // Cannot use createWithBytes if we want the pixel buffer backed by an IOSurface
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &pb)

        guard let pixelBuffer = pb else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let dest = CVPixelBufferGetBaseAddress(pixelBuffer)
        memcpy(dest, bytes, width * height * 4)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        free(bytes)
        
        return pixelBuffer
    }

    var image: UIImage? {

        let bytesPerRow = width * 4
        let imageByteCount: Int = width * height * 4

        guard let imageBytes = malloc(imageByteCount) else { return nil }
        getBytes(
            imageBytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: size),
            mipmapLevel: 0
        )

        let provider = CGDataProvider(dataInfo: nil, data: imageBytes, size: imageByteCount) { (rawPointer, pointer, i) in
            pointer.deallocate(bytes: i, alignedTo: 0)
            free(rawPointer)
        }

        var bitmapInfo: CGBitmapInfo!
        if pixelFormat == .bgra8Unorm {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(.byteOrder32Little)
        } else if pixelFormat == .rgba8Unorm {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Big)
        } else {
            free(imageBytes)
            return nil
        }

        let renderingIntent = CGColorRenderingIntent.defaultIntent
        guard let imageRef = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: renderingIntent
            ) else {
                free(imageBytes)
                return nil
        }
        
        let image = UIImage(cgImage: imageRef, scale: 0.0, orientation: .up).copy() as? UIImage

//        free(imageBytes)

        return image;
    }
    
    func copy(device: MTLDevice) -> MTLTexture {
        let data = bytes()!
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        let copy = device.makeTexture(descriptor: descriptor)
        copy?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: data, bytesPerRow: MemoryLayout<Float>.size * width)
        free(data)
        return copy!
    }
}

func dataProviderRef(from texture: MTLTexture) -> CGDataProvider {
    let pixelCount: Int = texture.width * texture.height
    var imageBytes = [UInt8](repeating: 0, count: pixelCount * 4)
    let providerRef = CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * 4 * MemoryLayout<UInt8>.size))
    return providerRef!
}

// MARK: - UIImage
extension UIImage {
    
    convenience init(texture: MTLTexture) {
        
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let bytesPerRow: UInt = UInt(texture.width * 4)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        
        let cgim = CGImage(
            width: texture.width,
            height: texture.height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: Int(bytesPerRow),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProviderRef(from: texture),
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        
        self.init(cgImage: cgim!)
    }
    
    // Something wrong with the scale
    func scaleToFill(_ size: CGSize) -> UIImage {
        
        let scaledImage: UIImage
        if size == CGSize.zero {
            scaledImage = self
        } else {
            let scalingFactor = size.width / self.size.width > size.height / self.size.height ? size.width / self.size.width : size.height / self.size.height
            let newSize = CGSize(width: self.size.width * scalingFactor,
                                 height: self.size.height * scalingFactor)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let origin = CGPoint(x: (size.width - newSize.width) / 2, y: (size.height - newSize.height) / 2)
            let rect = CGRect(origin: origin, size: newSize)
            self.draw(in: rect)
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
            
            UIGraphicsEndImageContext()
        }
        return scaledImage
    }
    
    func scaleToFit(_ size: CGSize) -> UIImage {
        
        // Need to set clear color
        
        let ratio = self.size.width / self.size.height
        let sizeRatio = size.width / size.height
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
        
        if ratio > sizeRatio {
            x = 0.0
            width = size.width
            height = size.width / ratio
            y = (size.height - height)/2.0
        }
        else {
            y = 0.0
            height = size.height
            width = size.height * ratio
            x = (size.width - width)/2.0
        }
        
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        context?.fill(rect)
        self.draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func center(_ size: CGSize) -> UIImage {
        // Not working
        
        let x = (self.size.width  - size.width )/4.0
        let y = (self.size.height - size.height)/4.0
        //
        //        let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
        //        let imageRef = CGImageCreateWithImageInRect(CGImage, rect);
        //        return UIImage(CGImage: imageRef!)
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
        context?.fill(rect)
        self.draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func resize(to size: CGSize) -> UIImage? {
        
        guard let cgImage = cgImage,
            let colorSpace = cgImage.colorSpace else { return nil }
        
        let width = cgImage.width / 2
        let height = cgImage.height / 2
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let bitmapInfo = cgImage.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: CGSize(width: CGFloat(width), height: CGFloat(height))))
        
        let scaledImage = context.makeImage().flatMap { UIImage(cgImage: $0) }
        
        return scaledImage
    }
    
    func texture(_ device: MTLDevice) -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: device)
        
        guard let cgImage = self.cgImage else {
            print("Error loading CGImage")
            return nil
        }
        
        let options = [ MTKTextureLoader.Option.SRGB : NSNumber(value: false) ]
        return try? textureLoader.newTexture(cgImage: cgImage, options: options)
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
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        let region = MTLRegionMake2D(0, 0, width, height)

        guard let bytes = data else {
            return nil
        }
        
        texture.replace(region: region, mipmapLevel: 0, withBytes: bytes, bytesPerRow: bytesPerRow)
        
        free(bytes)
        
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


// MARK: - AVCaptureDevice
extension AVCaptureDevice {
    
    func configureForHighestFrameRate(max: Double = 240.0) {
        
        guard let format = formats.filter({
            $0.maxFrameRateRange?.maxFrameRate ?? Double.greatestFiniteMagnitude <= max
        }).sorted(by: { format1, format2 in
            return format1.maxFrameRateRange?.maxFrameRate ?? 0 > format2.maxFrameRateRange?.maxFrameRate ?? 0
        }).first else {
            return
        }
        
        print("Max Format: \(format.maxFrameRateRange?.maxFrameRate ?? 0) FPS")
        
        do {
            try lockForConfiguration()
            activeFormat = format
            activeVideoMinFrameDuration = format.maxFrameRateRange!.minFrameDuration
            activeVideoMaxFrameDuration = format.maxFrameRateRange!.minFrameDuration
            unlockForConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - AVCaptureDevice.Format
extension AVCaptureDevice.Format {
    
    var maxFrameRateRange: AVFrameRateRange? {
        return videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate > $1.maxFrameRate }.first
    }
}


// MARK: - UIColor
extension UIColor {
    
    func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        
        var red  : CGFloat = 0
        var green: CGFloat = 0
        var blue : CGFloat = 0
        var alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        } else {
            return nil
        }
    }
}


// MARK: CVPixelBuffer
func minMax(from pixelBuffer: CVPixelBuffer, format: MTLPixelFormat) -> (Float, Float) {
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    let pixelBufferPointer = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    guard var pointer = pixelBufferPointer?.assumingMemoryBound(to: Float.self) else {
        return (0.0, 0.0)
    }
    
    let increment = bytesPerRow/MemoryLayout<Float>.size  // Check this
    var min =  Float.greatestFiniteMagnitude
    var max = -Float.greatestFiniteMagnitude
    
    for _ in 0 ..< height {
        for i in 0 ..< width {
            let val = pointer[i]
            if !val.isNaN {
                if val > max { max = val }
                if val < min { min = val }
            }
        }
        pointer += increment
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    
    return (min, max)
}


// Gross, I know
func fixOrientation(_ image: UIImage) -> UIImage? {
    if image.imageOrientation == .up {
        return image
    }
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    var transform: CGAffineTransform = CGAffineTransform.identity
    
    switch image.imageOrientation {
    case .down, .downMirrored:
        transform = transform.translatedBy(x: image.size.width, y: image.size.height)
        transform = transform.rotated(by: CGFloat.pi)
    case .left, .leftMirrored:
        transform = transform.translatedBy(x: image.size.width, y: 0)
        transform = transform.rotated(by: CGFloat.pi/2.0)
    case .right, .rightMirrored:
        transform = transform.translatedBy(x: 0, y: image.size.height)
        transform = transform.rotated(by: -CGFloat.pi/2.0)
    default:
        break
    }
    
    switch image.imageOrientation {
    case .upMirrored, .downMirrored:
        transform = transform.translatedBy(x: image.size.width, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
        transform = transform.translatedBy(x: image.size.height, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
    default:
        break
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    guard let context = CGContext(data: nil,
                                  width: Int(image.size.width),
                                  height: Int(image.size.height),
                                  bitsPerComponent: image.cgImage!.bitsPerComponent,
                                  bytesPerRow: 0, space: image.cgImage!.colorSpace!,
                                  bitmapInfo: image.cgImage!.bitmapInfo.rawValue) else {
                                    return nil
    }
    
    context.concatenate(transform)
    
    switch image.imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
    default:
        context.draw(image.cgImage!, in: CGRect(origin: .zero, size: image.size))
    }
    
    // And now we just create a new UIImage from the drawing context
    guard let CGImage = context.makeImage() else {
        return nil
    }
    
    return UIImage(cgImage: CGImage)
}

