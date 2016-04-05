//
//  MTLImage.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import Metal

public protocol MTLInput {
    var texture: MTLTexture  { get }
    var context: MTLContext  { get }
    var device : MTLDevice   { get }
    var targets: [MTLOutput] { get }
    
    func addTarget(var target: MTLOutput)
    func removeTarget(var target: MTLOutput)
    func removeAllTargets()
}

public protocol MTLOutput {
    var input: MTLInput? { get set }
}

public
class MTLImage: NSObject {
    
    public static var filters: [String: MTLFilter] = [
        "Brightness"   : MTLBrightnessFilter(),
        "Contrast"     : MTLContrastFilter(),
        "Convolution"  : MTLConvolutionFilter(),
        "Cross Hatch"  : MTLCrossHatchFilter(),
        "Emboss"       : MTLEmbossFilter(),
        "Exposure"     : MTLExposureFilter(),
        "Gaussian Blur": MTLGaussianBlurFilter(),
        "Invert"       : MTLInvertFilter(),
        "Levels"       : MTLLevelsFilter(),
        "Pixellate"    : MTLPixellateFilter(),
        "Polka Dot"    : MTLPolkaDotFilter(),
        "Saturation"   : MTLSaturationFilter(),
        "Sharpen"      : MTLSharpenFilter(),
        "White Balance": MTLWhiteBalanceFilter()
    ]
}

public func + (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

public func > (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}
