//
//  Mask.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/19/16.
//
//

struct MaskUniforms: Uniforms {
    var dummy: Float = 0.0
}

public
class Mask: Filter {
    
    var uniforms = MaskUniforms()
    
    public var mask: Input?
    public var background: Input?
    
    @objc public var add: Bool = false {
        didSet { needsUpdate = true }
    }
    
    @objc public var maskImage: UIImage? {
        didSet { updateMask() }
    }
    
    @objc public var backgroundImage: UIImage? {
        didSet { updateMask() }
    }
    
    @objc public var contentMode: UIViewContentMode = .scaleToFill {
        didSet {
            needsUpdate = true
            updateMask()
        }
    }
    
    func updateMask() {
        
        guard var maskImage = maskImage?.copy() as? UIImage,
            var backgroundImage = backgroundImage?.copy() as? UIImage,
            let textureSize = texture?.size else { return }
        
        let size = CGSize(width: textureSize.width, height: textureSize.height)
        
        switch contentMode {
        case .scaleAspectFit:
            maskImage = maskImage.scaleToFit(size)
            backgroundImage = backgroundImage.scaleToFit(size)
            break
        case .scaleAspectFill:
            maskImage = maskImage.scaleToFill(size)
            backgroundImage = backgroundImage.scaleToFill(size)
            break
        case .center:
            maskImage = maskImage.center(size)
            backgroundImage = backgroundImage.center(size)
        default: break
        }
        
        mask = Picture(image: maskImage)
        background = Picture(image: backgroundImage)
        needsUpdate = true
        
    }
    
    public init() {
        super.init(functionName: "mask")
        
        title = "Mask"
        
        let contentModeProperty = Property(key: "contentMode", title: "Content Mode", propertyType: .selection)
        contentModeProperty.selectionItems = contentModes
        
        properties = [
            Property(key: "maskImage", title: "Mask Image", propertyType: .image),
            Property(key: "backgroundImage", title: "Background Image", propertyType: .image),
            contentModeProperty,
            Property(key: "add", title: "Add", propertyType: .bool)
        ]
        
        update()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(functionName: "mask")
    }
    
    
    public override func processIfNeeded() {
        mask?.processIfNeeded()
        background?.processIfNeeded()
        super.processIfNeeded()
    }
    
    override public func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        commandEncoder.setTexture(mask?.texture, index: 2)
        commandEncoder.setTexture(background?.texture, index: 3)
    }
    
    
    private var contentModes = [0 : "Scale To Fill",
                                1 : "Scale Aspect Fit",
                                2 : "Scale Aspect Fill",
                                3 : "Center"]
}
