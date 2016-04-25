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
    
    func addTarget(target: MTLOutput)
    func removeTarget(target: MTLOutput)
    func removeAllTargets()
    func setNeedsUpdate()
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
         "Invert",
         "Kuwahara",
         "Levels",
         "Luminance Threshold",
         "Mask",
         "Perlin Noise",
         "Pixellate",
         "Polka Dot",
         "Saturation",
         "Selective HSL",
         "Sketch",
         "Sobel Edge Detection",
         "Sharpen",
         "Toon",
         "Vignette",
         "Water",
         "Watercolor",
         "White Balance"
    ]
    
    public class func filter(name: String) throws -> MTLFilter? {
        switch name.lowercaseString {
            case "blend"                : return MTLBlendFilter()
            case "brightness"           : return MTLBrightnessFilter()
            case "contrast"             : return MTLContrastFilter()
            case "cross hatch"          : return MTLCrossHatchFilter()
            case "distortion"           : return MTLDistortionFilter()
            case "emboss"               : return MTLEmbossFilter()
            case "exposure"             : return MTLExposureFilter()
            case "gaussian blur"        : return MTLGaussianBlurFilter()
            case "haze"                 : return MTLHazeFilter()
            case "invert"               : return MTLInvertFilter()
            case "kuwahara"             : return MTLKuwaharaFilter()
            case "levels"               : return MTLLevelsFilter()
//            case "luminance threshold"  : return MTLLuminanceThresholdFilter()
            case "mask"                 : return MTLMaskFilter()
            case "perlin noise"         : return MTLPerlinNoiseFilter()
            case "pixellate"            : return MTLPixellateFilter()
            case "polka dot"            : return MTLPolkaDotFilter()
            case "saturation"           : return MTLSaturationFilter()
            case "selective hsl"        : return MTLSelectiveHSLFilter()
            case "sketch"               : return MTLSketchFilter()
            case "sobel edge detection" : return MTLSobelEdgeDetectionFilter()
            case "sharpen"              : return MTLSharpenFilter()
            case "toon"                 : return MTLToonFilter()
            case "vignette"             : return MTLVignetteFilter()
            case "water"                : return MTLWaterFilter()
            case "watercolor"           : return MTLWatercolorFilter()
            case "white balance"        : return MTLWhiteBalanceFilter()
            default:                      throw  MTLError.InvalidFilterName
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
