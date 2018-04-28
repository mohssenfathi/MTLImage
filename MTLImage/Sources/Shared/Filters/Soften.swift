//
//  Soften.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/14/17.
//


/*
     Input ----> MaskGenerator ----> MaskBlend --> SharpenLuminance --> Output
            |                    |
             --> ToneCurve ------
 */


public
class Soften: Filter {
 
    public init() {
        super.init(functionName: nil)
        title = "Soften"
        properties = [
            Property(key: "intensity", title: "Intensity"),
            Property(key: "blurRadius", title: "Blur Radius"),
            Property(key: "exposure", title: "Exposure"),
        ]
        
        setup()
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(functionName: nil)
    }
    
    public override var texture: MTLTexture? {
        get {
            return terminalFilter.texture
        }
        set { /* No-op */ }
    }
    
    func setup() {
        
        title = "Soften"
        
        // Tone Curve
        toneCurve.compositePoints = defaultControlPoints
        toneCurve.intensity = intensity
        
        // Mask Blend
        maskBlend.background = toneCurve
        maskBlend.mask = maskGenerator
        
    }
    
    public override var needsUpdate: Bool {
        didSet {
            maskGenerator.needsUpdate = needsUpdate
            toneCurve.needsUpdate = needsUpdate
            maskBlend.needsUpdate = needsUpdate
        }
    }
    
    // MARK: - Properties
    @objc public var intensity : Float = 0.50 { didSet { needsUpdate = true } }
    @objc public var sharpness : Float = 0.10 { didSet { needsUpdate = true } }
    @objc public var exposure  : Float = 0.10 { didSet { needsUpdate = true } }
    @objc public var blurRadius: Float = 0.15 { didSet { needsUpdate = true } }
    
    public override var input: Input? {
        didSet {
            maskGenerator.input = input
            maskBlend.input = input
            toneCurve.input = input
        }
    }
    
    public override func update() {
        toneCurve.intensity = intensity * 0.5
        maskGenerator.exposure.exposure = exposure
        maskGenerator.highPass.blurRadius = blurRadius
        super.update()
    }
    
    public override func processIfNeeded() {
        terminalFilter.processIfNeeded()
        toneCurve.processIfNeeded()
        maskGenerator.processIfNeeded()
        super.processIfNeeded()
    }
    
    public override func process() { }
    
    
    // MARK: - Private
    private var terminalFilter: MTLObject { return maskBlend }
    
    private let toneCurve = ToneCurve()
    private let maskBlend = Mask()
    
    // Mask Generator
    var maskGenerator = MaskGenerator()
    
    private var defaultControlPoints: [CGPoint] = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 120/255.0, y: 146/255.0), CGPoint(x: 1.0, y: 1.0)]
    
}


class MaskGenerator: FilterGroup {
    
    /*
     Mask Generator:
     
     In --> Exposure -----> 0
         |       gbBlend ----> highPass -----> 0
          --> 1                           |       hlBlend  --> Out
                                           --> 1
     */
    
    override init() {
        super.init()
        
        title = "Mask Generator"
        
        gbBlend.blendMode = Blend.BlendMode.exclusion.rawValue

        exposure.exposure = 0.5
        highPass.blurRadius = 0.1
        
        add(exposure)
        add(gbBlend)
        add(highPass)
        add(highPassSkinSmooth)
        
        gbBlend.inputProvider = { [weak self] index in
            if index == 1 { return self?.exposure}
            return nil
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var texture: MTLTexture? {
        get { return highPassSkinSmooth.texture }
        set { /* No-op */ }
    }
    
    let exposure = Exposure()
    let highPass = HighPass()
    let gbBlend = Blend()
    let highPassSkinSmooth = HighPassSkinSmooth()
}



class HighPassSkinSmooth: Filter {
    
    public init() {
        super.init(functionName: "highPassSkinSmooth")
        title = "High Pass Skin Smooth"
        properties = [ ]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
