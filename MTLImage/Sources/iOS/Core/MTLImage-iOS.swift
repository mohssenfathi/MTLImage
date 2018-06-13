//
//  MTLImage.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import CloudKit
import Metal

public
class MTLImage: NSObject {
   
    public enum FilterType: String {
        case blend
        case bilinearScale = "bilinear scale"
        case boxBlur = "box blur"
        case brightness
        case buffer
        case contrast
        case colorGenerator = "color generator"
        case colorClamp = "color clamp"
        case colorMatrix = "color matrix"
        case colorMask = "color mask"
        case crop
        case crossHatch = "cross hatch"
        case dataOutput = "data output"
        case depthRenderer = "depth renderer"
        case dilate
        case emboss
        case exposure
        case gaussianBlur = "gaussian blur"
        case haze
        case highPass = "high pass"
        case highlightShadow = "highlight shadow"
        case histogram
        case hue
        case invert
        case kuwahara
        case lanczosScale = "lanczos scale"
        case lensFlare = "lens flare"
        case levels
        case lightLeak = "light leak"
        case lowPass = "low pass"
        case luminanceThreshold = "luminance threshold"
        case mask
        case maskBlend = "mask blend"
        case perlinNoise = "perlin noise"
        case pixellate
        case polkaDot = "polka dot"
        case resize
        case rollingAverage = "rolling average"
        case saturation
        case scatter
        case selectiveHSL = "selective hsl"
        case sketch
        case sobelEdgeDetection = "sobel edge detection"
        case soften
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
    
    public class func filter(_ type: FilterType) throws -> MTLObject {
        return type.filter()
    }
    
    public class func filter(_ name: String) -> MTLObject? {
        return FilterType(rawValue: name)?.filter()
    }
    
}

//    MARK: - NSCoding
public
extension MTLImage {
    public class func archive(_ filterGroup: FilterGroup) -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: filterGroup)
    }
    
    public class func unarchive(_ data: Data) -> FilterGroup? {        
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? FilterGroup
    }
}


//    MARK: - CoreData
public
extension MTLImage {
    public class func save(_ filterGroup: FilterGroup, completion: ((_ success: Bool) -> ())?) {
        DataManager.sharedManager.save(filterGroup, completion: completion)
    }
    
    public class func remove(_ filterGroup: FilterGroup, completion: ((_ success: Bool) -> ())?) {
        DataManager.sharedManager.remove(filterGroup, completion: completion)
    }
    
    public class func savedFilterGroups() -> [FilterGroup] {
        return DataManager.sharedManager.savedFilterGroups()
    }
}


//    MARK: - CloudKit
public
extension MTLImage {

    public class func filterGroup(_ record: CKRecord) -> FilterGroup? {
        
        let asset: CKAsset = record["filterData"] as! CKAsset
        guard let data = try? Data(contentsOf: asset.fileURL) else {
            return nil
        }
        
        return MTLImage.unarchive(data)
    }
    
    public class func upload(_ filterGroup: FilterGroup, container: CKContainer, completion: ((_ record: CKRecord?, _ error: Error?) -> ())?) {
        CloudKitManager.sharedManager.upload(filterGroup, container: container) { (record, error) in
            completion?(record, error)
        }
    }
    
}

//    MARK: - Error Handling
enum MTLError: Error {
    case invalidFilterName
}




// MARK: - FilterType

public
extension MTLImage.FilterType {
    
    public func filter() -> MTLObject {
        switch self {
        case .blend:                    return Blend()
        case .boxBlur:                  return BoxBlur()
        case .brightness:               return Brightness()
        case .buffer:                   return Buffer()
        case .colorClamp:               return ColorClamp()
        case .colorGenerator:           return ColorGenerator()
        case .colorMatrix:              return ColorMatrix()
        case .colorMask:                return ColorMask()
        case .contrast:                 return Contrast()
        case .crop:                     return Crop()
        case .crossHatch:               return CrossHatch()
        case .dataOutput:               return DataOutput()
        case .dilate:                   return Dilate()
        case .emboss:                   return Emboss()
        case .exposure:                 return Exposure()
        case .gaussianBlur:             return GaussianBlur()
        case .haze:                     return Haze()
        case .highPass:                 return HighPass()
        case .highlightShadow:          return HighlightShadow()
        case .histogram:                return Histogram()
        case .hue:                      return Hue()
        case .invert:                   return Invert()
        case .kuwahara:                 return Kuwahara()
        case .lanczosScale:             return LanczosScale()
        case .lensFlare:                return LensFlare()
        case .levels:                   return Levels()
        case .lightLeak:                return LightLeak()
        case .lowPass:                  return LowPass()
        case .luminanceThreshold:       return LuminanceThreshold()
        case .mask:                     return Mask()
        case .maskBlend:                return MaskBlend()
        case .perlinNoise:              return PerlinNoise()
        case .pixellate:                return Pixellate()
        case .polkaDot:                 return PolkaDot()
        case .resize:                   return Resize()
        case .rollingAverage:           return RollingAverage()
        case .saturation:               return Saturation()
        case .scatter:                  return Scatter()
        case .selectiveHSL:             return SelectiveHSL()
        case .sketch:                   return Sketch()
        case .sobelEdgeDetection:       return SobelEdgeDetection()
        case .soften:                   return Soften()
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
            
        /// iOS 11 only
        case .depthRenderer:
            if #available(iOS 11.0, *) { return DepthRenderer() }
            else { return Filter(functionName: nil) }
            
        case .bilinearScale:
            if #available(iOS 11.0, *) { return BilinearScale() }
            else { return Filter(functionName: nil) }
        }
    }
    
    public var title: String {
        return rawValue.capitalized
    }
    
    public static var all: [MTLImage.FilterType] {
        return [
            .soften, .blend, .boxBlur, .brightness, .buffer, .contrast, .colorGenerator, .colorMatrix,
            .colorMask, .crop, .crossHatch, .dataOutput, .depthRenderer, .dilate, .emboss,
            .exposure, .gaussianBlur, .haze, .highPass, .highlightShadow, .histogram, .hue,
            .invert, .kuwahara, .lanczosScale, .lensFlare, .levels, .lightLeak, .lowPass,
            .luminanceThreshold, .mask, .perlinNoise, .pixellate, .polkaDot, .resize,
            .rollingAverage, .saturation, .scatter, .selectiveHSL, .sketch, .sobelEdgeDetection,
            .sharpen, .tent, .toneCurve, .toon, .transform, .unsharpMask, .vignette,
            .voronoi, .water, .whiteBalance, .xyDerivative, .colorClamp, .bilinearScale
        ]
    }
    
}


/// Constants
let kMaxBuffersInFlight: Int = 3
