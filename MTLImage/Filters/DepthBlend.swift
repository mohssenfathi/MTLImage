//
//  DepthBlend.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/9/17.
//


struct DepthBlendUniforms: Uniforms {
    var lowerThreshold: Float = 0.8
}

public
class DepthBlend: Filter {
        
    var uniforms = DepthBlendUniforms()
    let depthRenderer = DepthRenderer()
    let resize = Resize()
    let blur = GaussianBlur()
    
    var lowerThreshold: Float = 0.8 {
        didSet {
            clamp(&lowerThreshold, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "depthBlend")
        blur.sigma = 0.1
        title = "Depth Blend"
        properties = [Property(key: "lowerThreshold", title: "Lower Threshold")]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        super.update()
        
        uniforms.lowerThreshold = lowerThreshold
        updateUniforms(uniforms: uniforms)
    }
    
    public override func process() {
        blur.process()
        super.process()
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        commandEncoder.setTexture(blur.texture, index: 2)
        commandEncoder.setTexture((source as? Camera)?.texture, index: 3)
    }
    
    override public var input: Input? {
        didSet {
            if let camera = source as? Camera {
                camera.mode = .depth
                camera.addTarget(depthRenderer)
                
                if let width = camera.texture?.width, let height = camera.texture?.height {
                    resize.outputSize = MTLSize(width: width, height: height, depth: 1)
                }
                depthRenderer.addTarget(resize)
                resize.addTarget(blur)
            }
        }
    }
}
