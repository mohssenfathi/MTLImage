//
//  DepthToGrayscale.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/8/17.
//

struct DepthToGrayscaleUniforms: Uniforms {
    var offset: Float = 0.5
    var range: Float = 0.5
}

public
class DepthToGrayscale: Filter {
    
    var uniforms = DepthToGrayscaleUniforms()
    
    public var offset: Float = 0.5 {
        didSet {
//            clamp(&offset, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var range: Float = 0.5 {
        didSet {
//            clamp(&range, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "depthToGrayscale")
        title = "Depth To Grayscale"
        properties = [
            Property(key: "offset", title: "Offset"),
            Property(key: "range", title: "Range")
        ]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.offset = offset
        uniforms.range = range
        updateUniforms(uniforms: uniforms)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        if let context = (source as? Camera)?.depthContext {
            if context.minDepth < offset { offset = context.minDepth }
            if context.maxDepth < range  { range  = context.maxDepth }
        }
    }
}
