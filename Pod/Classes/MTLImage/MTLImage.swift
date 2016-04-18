//
//  MTLImage.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
#if !(TARGET_IPHONE_SIMULATOR)
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
    
    public static var filters: [String: MTLFilter] = [
        "Brightness"           : MTLBrightnessFilter(),
        "Contrast"             : MTLContrastFilter(),
        "Cross Hatch"          : MTLCrossHatchFilter(),
        "Emboss"               : MTLEmbossFilter(),
        "Exposure"             : MTLExposureFilter(),
        "Gaussian Blur"        : MTLGaussianBlurFilter(),
        "Haze"                 : MTLHazeFilter(),
        "Invert"               : MTLInvertFilter(),
        "Kuwahara"             : MTLKuwaharaFilter(),
        "Levels"               : MTLLevelsFilter(),
        "Mask"                 : MTLMaskFilter(),
        "Pixellate"            : MTLPixellateFilter(),
        "Polka Dot"            : MTLPolkaDotFilter(),
        "Saturation"           : MTLSaturationFilter(),
        "Selective HSL"        : MTLSelectiveHSLFilter(),
        "Sketch"               : MTLSketchFilter(),
        "Sobel Edge Detection" : MTLSobelEdgeDetectionFilter(),
        "Sharpen"              : MTLSharpenFilter(),
        "Toon"                 : MTLToonFilter(),
        "Vignette"             : MTLVignetteFilter(),
        "Water"                : MTLWaterFilter(),
        "White Balance"        : MTLWhiteBalanceFilter()
    ]
    
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
