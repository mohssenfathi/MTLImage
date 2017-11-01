//
//  HighPass.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/14/17.
//

public
class HighPass: Filter {
    
    @objc public var blurRadius: Float = 0.1 {
        didSet {
            blur.sigma = blurRadius
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "highPass")
        title = "High Pass"
        properties = [
            Property(key: "blurRadius", title: "Blur Radius")
        ]
        update()
    }
    
    public override func processIfNeeded() {
        blur.processIfNeeded()
        super.processIfNeeded()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        commandEncoder.setTexture(blur.texture, index: 2)
    }
    
//    override public func update() {
//        if input == nil { return }
//        uniforms.contrast = Tools.convert(contrast, oldMin: 0.0, oldMid: 0.5, oldMax: 1.0, newMin: 0.0, newMid: 1.0, newMax: 4.0)
//        updateUniforms(uniforms: uniforms)
//    }
    
    public override var input: Input? {
        didSet { blur.input = input }
    }
    
    private var blur = GaussianBlur()
}
