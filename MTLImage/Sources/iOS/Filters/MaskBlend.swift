//
//  MaskBlend.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/18.
//


struct MaskBlendUniforms: Uniforms {
    var showMask: Bool = false
}

public
class MaskBlend: Filter {
    
    public override var needsUpdate: Bool {
        didSet {
            maskInput?.needsUpdate = needsUpdate
            secondaryInput?.needsUpdate = needsUpdate
        }
    }
    
    public var maskInput: Input?
    public var secondaryInput: Input?
    
    var uniforms = MaskBlendUniforms()
    
    // Useful for debugging
    public var showMask: Bool = false { didSet { needsUpdate = true } }
    
    public init() {
        super.init(functionName: "maskBlend")
        title = "Mask Blend"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func update() {
        super.update()
        
        uniforms.showMask = showMask
        updateUniforms(uniforms: uniforms, size: MemoryLayout<MaskBlendUniforms>.size)
    }
    
    public override func processIfNeeded() {
        maskInput?.processIfNeeded()
        secondaryInput?.processIfNeeded()
        super.processIfNeeded()
    }
    
    override var shouldProcess: Bool {
        return secondaryInput?.texture != nil &&  maskInput?.texture != nil
    }
    
    public override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        commandEncoder.setTexture(secondaryInput?.texture, index: 2)
        commandEncoder.setTexture(maskInput?.texture, index: 3)
    }
    
    public override func copy() -> Any {
        guard let copy = super.copy() as? MaskBlend else {
            return super.copy()
        }
        copy.maskInput = self.maskInput
        copy.secondaryInput = self.secondaryInput
        return copy
    }
}
