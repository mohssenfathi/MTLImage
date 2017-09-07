//
//  MTLImage.swift
//  MTLImage_macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation
import Metal

public
class MTLImage: NSObject {
    
    public enum FilterType: String {
        case boxBlur = "box blur"
        case brightness
        case buffer
        case contrast
        case colorMask = "color mask"
        case crop
        case crossHatch = "cross hatch"
        case dataOutput = "data output"
        case dilate
        case emboss
        case exposure
        case gaussianBlur = "gaussian blur"
        case haze
        case highlightShadow = "highlight shadow"
        case histogram
        case hue
        case invert
        case kuwahara
        case lanczosScale = "lanczos scale"
        case lensFlare = "lens flare"
        case levels
        case luminanceThreshold = "luminance threshold"
        case mask
        case perlinNoise = "perlin noise"
        case pixellate
        case polkaDot = "polka dot"
        case resize
        case rollingAverage = "rolling average"
        case saturation
        case sketch
        case sobelEdgeDetection = "sobel edge detection"
        case sharpen
        case tent
        case toneCurve = "tone curve"
        case toon
        case transform
        case unsharpMask = "unsharp mask"
        case vignette
        case voronoi
        case water
        case whiteBalance = "white balance"
        case xyDerivative = "XY derivative"
    }
   
    public static var filters: [String] = {
        return FilterType.all.map { $0.title }
    }()
    
    public class func filter(_ type: FilterType) throws -> MTLObject? {
        return type.filter()
    }
    
    public class func filter(_ name: String) -> MTLObject? {
        return FilterType(rawValue: name)?.filter()
    }
    
    //    MARK: - Error Handling
    enum MTLError: Error {
        case invalidFilterName
    }
 
}

// MARK: - FilterType

public
extension MTLImage.FilterType {
    
    public func filter() -> MTLObject {
        switch self {
        case .boxBlur:                  return BoxBlur()
        case .brightness:               return Brightness()
        case .buffer:                   return Buffer()
        case .contrast:                 return Contrast()
        case .colorMask:                return ColorMask()
        case .crop:                     return Crop()
        case .crossHatch:               return CrossHatch()
        case .dataOutput:               return DataOutput()
        case .dilate:                   return Dilate()
        case .emboss:                   return Emboss()
        case .exposure:                 return Exposure()
        case .gaussianBlur:             return GaussianBlur()
        case .haze:                     return Haze()
        case .highlightShadow:          return HighlightShadow()
        case .histogram:                return Histogram()
        case .hue:                      return Hue()
        case .invert:                   return Invert()
        case .kuwahara:                 return Kuwahara()
        case .lanczosScale:             return LanczosScale()
        case .lensFlare:                return LensFlare()
        case .levels:                   return Levels()
        case .luminanceThreshold:       return LuminanceThreshold()
        case .mask:                     return Mask()
        case .perlinNoise:              return PerlinNoise()
        case .pixellate:                return Pixellate()
        case .polkaDot:                 return PolkaDot()
        case .resize:                   return Resize()
        case .rollingAverage:           return RollingAverage()
        case .saturation:               return Saturation()
        case .sketch:                   return Sketch()
        case .sobelEdgeDetection:       return SobelEdgeDetection()
        case .sharpen:                  return Sharpen()
        case .tent:                     return Tent()
        case .toneCurve:                return ToneCurve()
        case .toon:                     return Toon()
        case .transform:                return Transform()
        case .unsharpMask:              return UnsharpMask()
        case .vignette:                 return Vignette()
        case .voronoi:                  return Voronoi()
        case .water:                    return Water()
        case .whiteBalance:             return WhiteBalance()
        case .xyDerivative:             return XYDerivative()
        }
    }
    
    public var title: String {
        return rawValue.capitalized
    }
    
    public static var all: [MTLImage.FilterType] {
        return [
            .boxBlur, .brightness, .buffer, .contrast, .colorMask, .crop,
            .crossHatch, .dataOutput, .dilate, .emboss,
            .exposure, .gaussianBlur, .haze, .highlightShadow, .histogram, .hue,
            .invert, .kuwahara, .lanczosScale, .lensFlare, .levels,
            .luminanceThreshold, .mask, .perlinNoise, .pixellate, .polkaDot, .resize,
            .rollingAverage, .saturation, .sketch, .sobelEdgeDetection,
            .sharpen, .tent, .toneCurve, .toon, .transform, .unsharpMask, .vignette,
            .voronoi, .water, .whiteBalance, .xyDerivative
        ]
    }
    
}

