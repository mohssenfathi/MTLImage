//
//  MTLBlendFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/17/16.
//
//

import UIKit

struct BlendUniforms {
    var mix: Float = 0.5
    var blendMode: Float = 0
}

public
class MTLBlendFilter: MTLFilter {
    
    var uniforms = BlendUniforms()
    private var blendTexture: MTLTexture?
    private var originalBlendImage: UIImage?
    
    var blendOriginal: Bool = true {
        didSet {
            needsUpdate = true
            update()
        }
    }
    
    public var mix: Float = 1.0 {
        didSet {
            clamp(&mix, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var blendMode: Int = 0 {
        didSet {
            clamp(&blendMode, low: 0, high: 12)
            needsUpdate = true
            update()
        }
    }
    
    public var contentMode: UIViewContentMode = .ScaleToFill {
        didSet {
            needsUpdate = true
            update()
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
                case .ScaleAspectFit:
                    blendImage = originalBlendImage?.scaleToFit(originalImage!.size)
                    break
                case .ScaleAspectFill:
                    blendImage = originalBlendImage?.scaleToFill(originalImage!.size)
                    break
                case .Center:
                    blendImage = originalBlendImage?.center(originalImage!.size)
                default:
                    break
                }
            }
            
            needsUpdate = true
            blendTexture = nil
            update()
        }
    }
    
    public init() {
        super.init(functionName: "blend")
        title = "Blend"
        uniforms.mix = 1.0 - mix
        
        let blendModeProperty = MTLProperty(key: "blendMode", title: "Blend Mode", propertyType: .Selection)
        blendModeProperty.selectionItems = [0  : "Normal",
                                            1  : "Overlay",
                                            2  : "Lighten",
                                            3  : "Darken",
                                            4  : "Soft Light",
                                            5  : "Hard Light",
                                            6  : "Multiply",
                                            7  : "Subtract",
                                            8  : "Divide",
                                            9  : "Color Burn",
                                            10 : "Color Dodge",
                                            11 : "Screen",
                                            12 : "Difference" ]
        
        let contentModeProperty = MTLProperty(key: "contentMode", title: "Content Mode", propertyType: .Selection)
        contentModeProperty.selectionItems = [0 : "Scale To Fill",
                                              1 : "Scale Aspect Fit",
                                              2 : "Scale Aspect Fill",
                                              3 : "Center"]
        
        properties = [MTLProperty(key: "blendImage", title: "Blend Image", propertyType: .Image),
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
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(BlendUniforms), options: .CPUCacheModeDefaultCache)
    }
 
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if blendTexture == nil {
            createBlendTexture()
        }
        commandEncoder.setTexture(blendTexture, atIndex: 2)
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
