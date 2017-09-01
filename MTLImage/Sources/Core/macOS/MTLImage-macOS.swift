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
    
    public static var filters: [String] = [
        "Blend",
        "Box Blur",
        "Brightness",
        "Buffer",
        "Contrast",
        "Color Mask",
        "Crop",
        "Copy",
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
//        case "blend"                          : return Blend()
        case "box blur"                       : return BoxBlur()
        case "brightness"                     : return Brightness()
        case "buffer"                         : return Buffer()
        case "contrast"                       : return Contrast()
        case "color mask"                     : return ColorMask()
        case "copy"                           : return Copy()
        case "crop"                           : return Crop()
        case "cross hatch"                    : return CrossHatch()
        case "data output"                    : return DataOutput()
//        case "depth blend"                    : return DepthBlend()
//        case "depth renderer"                 : return DepthRenderer()
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
//        case "low pass"                       : return LowPass()
        case "luminance threshold"            : return LuminanceThreshold()
        case "mask"                           : return Mask()
        case "perlin noise"                   : return PerlinNoise()
        case "pixellate"                      : return Pixellate()
        case "polka dot"                      : return PolkaDot()
        case "resize"                         : return Resize()
        case "rolling average"                : return RollingAverage()
        case "saturation"                     : return Saturation()
//        case "scatter"                        : return Scatter()
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

        default: throw  MTLError.invalidFilterName
        }
        
    }
    
    //    MARK: - Error Handling
    enum MTLError: Error {
        case invalidFilterName
    }
    
}
