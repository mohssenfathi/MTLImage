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

public protocol MTLInput {
    
    var texture: MTLTexture? { get }
    var context: MTLContext  { get }
    var device : MTLDevice   { get }
    var targets: [MTLOutput] { get }
    
    var title      : String  { get set }
    var identifier : String! { get set }
    var needsUpdate: Bool    { get set }
    
    func addTarget(_ target: MTLOutput)
    func removeTarget(_ target: MTLOutput)
    func removeAllTargets()
}

public protocol MTLOutput {
    
    var input     : MTLInput? { get set }
    var title     : String    { get set }
    var identifier: String!   { get set }
    
}

public
class MTLImage: NSObject {
    
    public static var filters: [String] = [
         "Blend",
         "Box Blur",
         "Brightness",
         "Canny Edge Detection",
         "Contrast",
         "Crop",
         "Cross Hatch",
         "Digit Recognizer",
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
         "Levels",
         "Luminance Threshold",
         "Mask",
         "Perlin Noise",
         "Pixellate",
         "Polka Dot",
         "Saturation",
         "Scatter",
         "Sketch",
         "Sobel Edge Detection",
         "Sharpen",
         "Tent",
         "Tone Curve",
         "Toon",
         "Unsharp Mask",
         "Vignette",
         "Water",
         "White Balance",
         "XY Derivative"
    ]
    
    public class func filter(_ name: String) throws -> MTLObject? {
        switch name.lowercased() {
            
            // Core
            case "blend"                          : return MTLBlendFilter()
            case "box blur"                            : return MTLBoxBlurFilter()
            case "brightness"                     : return MTLBrightnessFilter()
            case "canny edge detection"           : return MTLCannyEdgeDetectionFilterGroup()
            case "contrast"                       : return MTLContrastFilter()
            case "crop"                           : return MTLCropFilter()
            case "cross hatch"                    : return MTLCrossHatchFilter()
            case "dilate"                         : return MTLDilateFilter()
            case "emboss"                         : return MTLEmbossFilter()
            case "exposure"                       : return MTLExposureFilter()
            case "gaussian blur"                  : return MTLGaussianBlurFilter()
            case "haze"                           : return MTLHazeFilter()
            case "highlight/shadow"               : return MTLHighlightShadowFilter()
            case "histogram"                      : return MTLHistogramFilter()
            case "hue"                            : return MTLHueFilter()
            case "invert"                         : return MTLInvertFilter()
            case "kuwahara"                       : return MTLKuwaharaFilter()
            case "lanczos scale"                  : return MTLLanczosScaleFilter()
            case "levels"                         : return MTLLevelsFilter()
            case "luminance threshold"            : return MTLLuminanceThresholdFilter()
            case "mask"                           : return MTLMaskFilter()
            case "perlin noise"                   : return MTLPerlinNoiseFilter()
            case "pixellate"                      : return MTLPixellateFilter()
            case "polka dot"                      : return MTLPolkaDotFilter()
            case "saturation"                     : return MTLSaturationFilter()
            case "scatter"                        : return MTLScatterFilter()
            case "sketch"                         : return MTLSketchFilter()
            case "sobel edge detection"           : return MTLSobelEdgeDetectionFilter()
            case "sharpen"                        : return MTLSharpenFilter()
            case "tent"                           : return MTLTentFilter()
            case "tone curve"                     : return MTLToneCurveFilter()
            case "toon"                           : return MTLToonFilter()
            case "unsharp mask"                   : return MTLUnsharpMaskFilter()
            case "vignette"                       : return MTLVignetteFilter()
            case "water"                          : return MTLWaterFilter()
            case "white balance"                  : return MTLWhiteBalanceFilter()
            case "xy derivative"                  : return MTLXYDerivativeFilter()
            
            // Machine Learning
            case "digit recognizer":
                do    { return try! MTLImage.machineLearningFilter(name) }
                catch { throw  MTLError.invalidFilterName                }
            
            
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
    
}

//    MARK: - NSCoding
public
extension MTLImage {
    public class func archive(_ filterGroup: MTLFilterGroup) -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: filterGroup)
    }
    
    public class func unarchive(_ data: Data) -> MTLFilterGroup? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? MTLFilterGroup
    }
}


//    MARK: - CoreData
public
extension MTLImage {
    public class func save(_ filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        MTLDataManager.sharedManager.save(filterGroup, completion: completion)
    }
    
    public class func remove(_ filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        MTLDataManager.sharedManager.remove(filterGroup, completion: completion)
    }
    
    public class func savedFilterGroups() -> [MTLFilterGroup] {
        return MTLDataManager.sharedManager.savedFilterGroups()
    }
}


//    MARK: - CloudKit
public
extension MTLImage {

    public class func filterGroup(_ record: CKRecord) -> MTLFilterGroup? {
        
        let asset: CKAsset = record["filterData"] as! CKAsset
        guard let data = try? Data(contentsOf: asset.fileURL) else {
            return nil
        }
        
        return MTLImage.unarchive(data)
    }
    
    public class func upload(_ filterGroup: MTLFilterGroup, container: CKContainer, completion: ((record: CKRecord?, error: NSError?) -> ())?) {
        MTLCloudKitManager.sharedManager.upload(filterGroup, container: container) { (record, error) in
            completion?(record: record, error: error)
        }
    }
    
}


//    MARK: - Overloading

infix operator --> { associativity left precedence 80 }
public func -->(left: MTLInput , right: MTLOutput) -> MTLOutput {
    left.addTarget(right)
    return right
}
public func --> (left: MTLInput , right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}
public func --> (left: MTLObject, right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}
public func --> (left: MTLObject, right: MTLOutput) {
    left.addTarget(right)
}

public func + (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

public func > (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

enum MTLError: ErrorProtocol {
    case invalidFilterName
}
