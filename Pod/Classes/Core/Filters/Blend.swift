//
//  Blend.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/17/16.
//
//

struct BlendUniforms: Uniforms {
    var mix: Float = 1.0
    var blendMode: Float = 0
}

public enum BlendMode: Int {
    
    case add, alpha, colorBlend, colorBurn, colorDodge, darken, difference, dissolve, divide, exclusion, hardlight,
    linearBurn, lighten, linearDodge, lumosity, multiply, normal, overlay, screen, soflight, subtract
    
    static func numberOfBlendModes() -> Int {
        return BlendMode.subtract.rawValue + 1
    }
    
    func title() -> String {
        
        switch self {
            
        case .add:           return "Add"
        case .alpha:         return "Alpha"
        case .colorBlend:    return "ColorBlend"
        case .colorBurn:     return "ColorBurn"
        case .colorDodge:    return "ColorDodge"
        case .darken:        return "Darken"
        case .difference:    return "Difference"
        case .dissolve:      return "Dissolve"
        case .divide:        return "Divide"
        case .exclusion:     return "Exclusion"
        case .hardlight:     return "HardLight"
        case .linearBurn:    return "LinearBurn"
        case .lighten:       return "Lighten"
        case .linearDodge:   return "LinearDodge"
        case .lumosity:      return "Lumosity"
        case .multiply:      return "Multiply"
        case .normal:        return "Normal"
        case .overlay:       return "Overlay"
        case .screen:        return "Screen"
        case .soflight:      return "SoftLight"
        case .subtract:      return "Subtract"
                        
        }
    }
}

public
class Blend: MTLFilter {
    
    var uniforms = BlendUniforms()
    private var blendTexture: MTLTexture?
    private var originalBlendImage: UIImage?
    
    lazy private var blendModes: [Int: String] = {
        var dict = [Int : String]()
        for i in 0 ..< BlendMode.numberOfBlendModes() {
            dict[i] = BlendMode(rawValue: i)!.title()
        }
        return dict
    }()
    
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
    
    public var blendMode: Int = BlendMode.alpha.rawValue {
        didSet {
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
        commandEncoder.setTexture(blendTexture, index: 2)
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
