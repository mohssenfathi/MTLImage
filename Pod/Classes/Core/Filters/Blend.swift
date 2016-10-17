//
//  Blend.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/17/16.
//
//

import UIKit

struct BlendUniforms: Uniforms {
    var mix: Float = 1.0
    var blendMode: Float = 0
}

public
class Blend: MTLFilter {
    
    var uniforms = BlendUniforms()
    private var blendTexture: MTLTexture?
    private var originalBlendImage: UIImage?
    
    private var blendModes = [ 0 : "Add",
                               1  : "Alpha",
                               2  : "ColorBlend",
                               3  : "ColorBurn",
                               4  : "ColorDodge",
                               5  : "Darken",
                               6  : "Difference",
                               7  : "Disolve",
                               8  : "Divide",
                               9  : "Exclusion",
                               10 : "HardLight",
                               11 : "LinearBurn",
                               12 : "Lighten",
                               13 : "LinearDodge",
                               14 : "Lumosity",
                               15 : "Multiply",
                               16 : "Normal",
                               17 : "Overlay",
                               18 : "Screen",
                               19 : "SoftLight",
                               20 : "Subtract" ]
    
    private var contentModes = [0 : "Scale To Fill",
                                1 : "Scale Aspect Fit",
                                2 : "Scale Aspect Fill",
                                3 : "Center"]
    
    var blendOriginal: Bool = true {
        didSet {
            needsUpdate = true
        }
    }
    
    public var mix: Float = 1.0 {
        didSet {
            clamp(&mix, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var blendMode: Int = 16 {
        didSet {
            clamp(&blendMode, low: 0, high: blendModes.count + 1)
            needsUpdate = true
        }
    }
    
    public var contentMode: UIViewContentMode = .scaleToFill {
        didSet {
            needsUpdate = true
            blendImage = originalBlendImage
        }
    }
    
    public var blendImage: UIImage? {
        willSet {
            if blendImage == nil {
                originalBlendImage = newValue?.copy() as? UIImage
            }
        }
        didSet {
            if blendImage != nil && originalImage != nil {
                blendOriginal = false
                
                switch contentMode {
                case .scaleAspectFit:
                    blendImage = originalBlendImage?.scaleToFit(originalImage!.size)
                    break
                case .scaleAspectFill:
                    blendImage = originalBlendImage?.scaleToFill(originalImage!.size)
                    break
                case .center:
                    blendImage = originalBlendImage?.center(originalImage!.size)
                default:
                    break
                }
            }
            
            needsUpdate = true
            blendTexture = nil
        }
    }
    
    public init() {
        super.init(functionName: "blend")
        title = "Blend"
        uniforms.mix = 1.0 - mix
        
        let blendModeProperty = MTLProperty(key: "blendMode", title: "Blend Mode", propertyType: .selection)
        blendModeProperty.selectionItems = blendModes
        
        let contentModeProperty = MTLProperty(key: "contentMode", title: "Content Mode", propertyType: .selection)
        contentModeProperty.selectionItems = contentModes
        
        properties = [MTLProperty(key: "blendImage", title: "Blend Image", propertyType: .image),
                      MTLProperty(key: "mix", title: "Mix"),
                      blendModeProperty, contentModeProperty]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.mix = mix
        uniforms.blendMode = Float(blendMode)
        updateUniforms(uniforms: uniforms)
    }
 
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        if blendTexture == nil || blendOriginal {
            createBlendTexture()
        }
        commandEncoder.setTexture(blendTexture, at: 2)
    }
    
    func createBlendTexture() {
        if blendOriginal == true {
            blendTexture = source?.texture
        }
        else if blendImage != nil {
            blendTexture = blendImage?.texture(device)
        }
    }
}
