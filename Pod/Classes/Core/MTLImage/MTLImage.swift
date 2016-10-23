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
    var commandBuffer: MTLCommandBuffer { get }
    
    var title      : String { get set }
    var identifier : String { get set }
    var needsUpdate: Bool   { get set }
    var continuousUpdate: Bool { get }
    
    func addTarget(_ target: MTLOutput)
    func removeTarget(_ target: MTLOutput)
    func removeAllTargets()
}

public protocol MTLOutput {
    
    var input     : MTLInput? { get set }
    var title     : String    { get set }
    var identifier: String    { get set }
}

public protocol Uniforms {

}

public
class MTLImage: NSObject {
   
    #if !(TARGET_OS_SIMULATOR)
    
    public static var filters: [String] = [
         "Blend",
         "Box Blur",
         "Brightness",
         "Buffer",
         "Contrast",
         "Crop",
         "Cross Hatch",
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
            case "crop"                           : return Crop()
            case "cross hatch"                    : return CrossHatch()
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
            case "luminance threshold"            : return LuminanceThreshold()
            case "mask"                           : return Mask()
            case "perlin noise"                   : return PerlinNoise()
            case "pixellate"                      : return Pixellate()
            case "polka dot"                      : return PolkaDot()
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
    
    #endif
    
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
    public class func save(_ filterGroup: MTLFilterGroup, completion: ((_ success: Bool) -> ())?) {
        MTLDataManager.sharedManager.save(filterGroup, completion: completion)
    }
    
    public class func remove(_ filterGroup: MTLFilterGroup, completion: ((_ success: Bool) -> ())?) {
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
    
    public class func upload(_ filterGroup: MTLFilterGroup, container: CKContainer, completion: ((_ record: CKRecord?, _ error: Error?) -> ())?) {
        MTLCloudKitManager.sharedManager.upload(filterGroup, container: container) { (record, error) in
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
public func --> (left: MTLInput , right: MTLOutput) -> MTLOutput {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: MTLInput , right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: MTLObject, right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: MTLObject, right: MTLOutput) {
    left.addTarget(right)
}

@discardableResult
public func + (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}

@discardableResult
public func > (left: MTLInput, right: MTLOutput) {
    left.addTarget(right)
}


//    MARK: - Error Handling
enum MTLError: Error {
    case invalidFilterName
}
