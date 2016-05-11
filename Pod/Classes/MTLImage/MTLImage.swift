//
//  MTLImage.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
#if !(TARGET_OS_SIMULATOR)
import Metal
#endif

public protocol MTLInput {
    var texture: MTLTexture? { get }
    var context: MTLContext  { get }
    var device : MTLDevice   { get }
    var targets: [MTLOutput] { get }
    var title: String { get set }
    var identifier: String! { get set }
    var needsUpdate: Bool { get set }
    
    func addTarget(target: MTLOutput)
    func removeTarget(target: MTLOutput)
    func removeAllTargets()
}

public protocol MTLOutput {
    var input: MTLInput? { get set }
    var title: String { get set }
    var identifier: String! { get set }
}

public
class MTLImage: NSObject {
    
    public static var filters: [String] = [
         "Blend",
         "Brightness",
         "Contrast",
         "Cross Hatch",
         "Distortion",
         "Emboss",
         "Exposure",
         "Gaussian Blur",
         "Haze",
         "Histogram",
         "Invert",
         "Kuwahara",
         "Levels",
         "Line Detection",
         "Luminance Threshold",
         "Mask",
         "Non Maximum Suppression",
         "Perlin Noise",
         "Pixellate",
         "Polka Dot",
         "Saturation",
         "Selective HSL",
         "Sketch",
         "Sobel Edge Detection",
         "Sobel Edge Detection Threshold",
         "Sharpen",
         "Toon",
         "Vignette",
         "Water",
         "Watercolor",
         "White Balance"
    ]
    
    public class func filter(name: String) throws -> MTLFilter? {
        switch name.lowercaseString {
            case "blend"                          : return MTLBlendFilter()
            case "brightness"                     : return MTLBrightnessFilter()
            case "contrast"                       : return MTLContrastFilter()
            case "cross hatch"                    : return MTLCrossHatchFilter()
            case "distortion"                     : return MTLDistortionFilter()
            case "emboss"                         : return MTLEmbossFilter()
            case "exposure"                       : return MTLExposureFilter()
            case "gaussian blur"                  : return MTLGaussianBlurFilter()
            case "haze"                           : return MTLHazeFilter()
            case "histogram"                      : return MTLHistogramFilter()
            case "invert"                         : return MTLInvertFilter()
            case "kuwahara"                       : return MTLKuwaharaFilter()
            case "levels"                         : return MTLLevelsFilter()
            case "line detection"                 : return MTLLineDetectionFilter()
            case "luminance threshold"            : return MTLLuminanceThresholdFilter()
            case "mask"                           : return MTLMaskFilter()
            case "non maximum suppression"        : return MTLNonMaximumSuppressionFilter()
            case "perlin noise"                   : return MTLPerlinNoiseFilter()
            case "pixellate"                      : return MTLPixellateFilter()
            case "polka dot"                      : return MTLPolkaDotFilter()
            case "saturation"                     : return MTLSaturationFilter()
            case "selective hsl"                  : return MTLSelectiveHSLFilter()
            case "sketch"                         : return MTLSketchFilter()
            case "sobel edge detection"           : return MTLSobelEdgeDetectionFilter()
            case "sobel edge detection threshold" : return MTLSobelEdgeDetectionThresholdFilter()
            case "sharpen"                        : return MTLSharpenFilter()
            case "toon"                           : return MTLToonFilter()
            case "vignette"                       : return MTLVignetteFilter()
            case "water"                          : return MTLWaterFilter()
            case "watercolor"                     : return MTLWatercolorFilter()
            case "white balance"                  : return MTLWhiteBalanceFilter()
            default:                                throw  MTLError.InvalidFilterName
        }
    }
    
    public class func save(filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        MTLDataManager.sharedManager.save(filterGroup, completion: completion)
    }
    
    public class func remove(filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        MTLDataManager.sharedManager.remove(filterGroup, completion: completion)
    }
    
    public class func savedFilterGroups() -> [MTLFilterGroup] {
        return MTLDataManager.sharedManager.savedFilterGroups()
    }
    
    public class func archive(filterGroup: MTLFilterGroup) -> NSData? {
        return NSKeyedArchiver.archivedDataWithRootObject(filterGroup)
    }
    
    public class func unarchive(data: NSData) -> MTLFilterGroup? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MTLFilterGroup
    }
}

public func + (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

public func > (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

enum MTLError: ErrorType {
    case InvalidFilterName
}



// A failed attempt at some abstraction...
// Possibly in the future, make MTLFilter and MTLFilterGroup subclasses of MTLObject

//public class MTLObject: NSObject, MTLInput, MTLOutput {
//
////    MARK: - MTLInput
//    public var texture: MTLTexture? { get { return nil } }
//    public var context: MTLContext  { get { return MTLContext() } }
//    public var device : MTLDevice   { get { return MTLCreateSystemDefaultDevice()! } }
//    public var targets: [MTLOutput] { get { return [] } }
//    public var needsUpdate: Bool    { get { return false } set {} }
//
//    public func addTarget(target: MTLOutput) {}
//    public func removeTarget(target: MTLOutput) {}
//    public func removeAllTargets() {}
//
//
////    MARK: - MTLOutput
//    public var input: MTLInput?    { get { return nil } set {} }
//    public var title: String       { get { return ""  } set {} }
//    public var identifier: String! { get { return ""  } set {} }
//
//}