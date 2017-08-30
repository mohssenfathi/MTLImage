//
//  MTLImage.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import CloudKit // later, test if module enabled
#if !(TARGET_OS_SIMULATOR)
import Metal
#endif

public
class MTLImage: NSObject {
   
    #if !(TARGET_OS_SIMULATOR)
    
    public static var filters: [String] = [
         "Blend",
         "Box Blur",
         "Brightness",
         "Buffer",
         "Contrast",
         "Color Mask",
         "Crop",
         "Cross Hatch",
         "Data Output",
         "Depth Blend",
         "Depth Renderer",
         "Dilate",
         "Emboss",
         "Exposure",
         "Gaussian Blur",
         "Haze",
         "Highlight/Shadow",
         "Histogram",
         "Hue",
         "Invert",
         "Kuwahara",
         "Lanczos Scale",
         "Lens Flare",
         "Levels",
         "Low Pass",
         "Luminance Threshold",
         "Mask",
         "Perlin Noise",
         "Pixellate",
         "Polka Dot",
         "Resize",
         "Rolling Average",
         "Saturation",
         "Scatter",
         "Sketch",
         "Sobel Edge Detection",
         "Sharpen",
         "Tent",
         "Tone Curve",
         "Toon",
         "Transform",
         "Unsharp Mask",
         "Vignette",
         "Voronoi",
         "Water",
         "White Balance",
         "XY Derivative"
    ]
    
    public class func filter(_ name: String) throws -> MTLObject? {
        switch name.lowercased() {
        
            // Core
            case "blend"                          : return Blend()
            case "box blur"                       : return BoxBlur()
            case "brightness"                     : return Brightness()
            case "buffer"                         : return Buffer()
            case "contrast"                       : return Contrast()
            case "color mask"                     : return ColorMask()
            case "crop"                           : return Crop()
            case "cross hatch"                    : return CrossHatch()
            case "data output"                    : return DataOutput()
            case "depth blend"                    : return DepthBlend()
            case "depth renderer"                 : return DepthRenderer()
            case "dilate"                         : return Dilate()
            case "emboss"                         : return Emboss()
            case "exposure"                       : return Exposure()
            case "gaussian blur"                  : return GaussianBlur()
            case "haze"                           : return Haze()
            case "highlight/shadow"               : return HighlightShadow()
            case "histogram"                      : return Histogram()
            case "hue"                            : return Hue()
            case "invert"                         : return Invert()
            case "kuwahara"                       : return Kuwahara()
            case "lanczos scale"                  : return LanczosScale()
            case "lens flare"                     : return LensFlare()
            case "levels"                         : return Levels()
            case "low pass"                       : return LowPass()
            case "luminance threshold"            : return LuminanceThreshold()
            case "mask"                           : return Mask()
            case "perlin noise"                   : return PerlinNoise()
            case "pixellate"                      : return Pixellate()
            case "polka dot"                      : return PolkaDot()
            case "resize"                         : return Resize()
            case "rolling average"                : return RollingAverage()
            case "saturation"                     : return Saturation()
            case "scatter"                        : return Scatter()
            case "sketch"                         : return Sketch()
            case "sobel edge detection"           : return SobelEdgeDetection()
            case "sharpen"                        : return Sharpen()
            case "tent"                           : return Tent()
            case "tone curve"                     : return ToneCurve()
            case "toon"                           : return Toon()
            case "transform"                      : return Transform()
            case "unsharp mask"                   : return UnsharpMask()
            case "vignette"                       : return Vignette()
            case "voronoi"                        : return Voronoi()
            case "water"                          : return Water()
            case "white balance"                  : return WhiteBalance()
            case "xy derivative"                  : return XYDerivative()
            
            // Machine Learning
            case "digit recognizer":
                do    { return try MTLImage.machineLearningFilter(name) }
                catch { throw  MTLError.invalidFilterName               }
            
            default: throw  MTLError.invalidFilterName
        }
    }
    
    class func machineLearningFilter(_ name: String) throws -> MTLObject? {
        #if(MTLIMAGE_MACHINE_LEARNING)
            switch name.lowercased() {
            case "digit recognizer"               : return MTLDigitRecognzier()
            default:                                throw  MTLError.invalidFilterName
            }
        #endif
        
        return nil
    }
    
    #endif
    
}

public
extension MTLImage {
    
    public static var isMetalSupported: Bool {
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        
        var supported = false
        
        #if os(tvOS)
            supported = device.supportsFeatureSet(.tvOS_GPUFamily1_v1)
        #elseif os(iOS)
            supported = device.supportsFeatureSet(.iOS_GPUFamily1_v1)
        #endif
        
        return supported
    }
}


public protocol Uniforms { }


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


//    MARK: - Operator Overloading

precedencegroup ChainPrecedence {
    associativity: left
}

infix operator --> : ChainPrecedence

@discardableResult
public func --> (left: Input , right: Output) -> Output {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: Input , right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: MTLObject, right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

public func --> (left: MTLObject, right: Output) {
    left.addTarget(right)
}

public func + (left: Input, right: Output) {
    left.addTarget(right)
}

public func > (left: Input, right: Output) {
    left.addTarget(right)
}


//    MARK: - Error Handling
enum MTLError: Error {
    case invalidFilterName
}
