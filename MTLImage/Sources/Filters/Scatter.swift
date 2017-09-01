//
//  Scatter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/18/16.
//
//

struct ScatterUniforms: Uniforms {
    var radius: Float = 0.5
}

public
class Scatter: Filter {
    
    var uniforms = ScatterUniforms()
    let noiseFilter = PerlinNoise()
    var noiseTexture: MTLTexture!
    
    @objc public var radius: Float = 0.5 {
        didSet {
            clamp(&radius, low: 0, high: 1)
            noiseTexture = nil
            needsUpdate = true
        }
    }
    
    @objc public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            noiseFilter.scale = scale/50.0
            noiseTexture = nil
            needsUpdate = true
        }
    }
    
    #if os(macOS)
    @objc public var noiseImage: NSImage? {
        didSet { updateNoiseImage() }
    }
    #else
    @objc public var noiseImage: UIImage? {
        didSet { updateNoiseImage() }
    }
    #endif
    
    
    public init() {
        super.init(functionName: "scatter")
        title = "Scatter"
        
        properties = [Property(key: "radius", title: "Radius"),
                      Property(key: "scale", title: "Scale"),
                      Property(key: "noiseImage", title: "Noise Image", propertyType: .image)]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.radius = radius * 40
        updateUniforms(uniforms: uniforms)
    }
    
    func updateNoiseTexture() {
        
        if noiseImage == nil {
            noiseTexture = noiseFilter.texture
            return
        }
        
        guard let inputTexture = input?.texture else { //noiseImage?.texture(device) else {
            noiseTexture = noiseFilter.texture
            return
        }

        let inputSize = CGSize(width: inputTexture.width, height: inputTexture.height)
        if noiseImage?.size != inputSize {
            noiseImage = noiseImage!.resize(to: inputSize)
        }
        
        #if os(macOS)
            noiseTexture = noiseImage?.texture(device: device)
        #else
            noiseTexture = noiseImage?.texture(device)
        #endif
    }
    
    
    func updateNoiseImage() {
        if let tex = input?.texture {
            let imageSize = CGSize(width: tex.width, height: tex.height)
            if noiseImage?.size.width != imageSize.width && noiseImage?.size.height != imageSize.height {
                let scaledImage = noiseImage?.scaleToFill(imageSize)  // Only calls itself once
                noiseImage = scaledImage
                return
            }
        }
        
        noiseTexture = nil
        needsUpdate = true
        update()
    }
    

    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        if noiseTexture == nil {
            updateNoiseTexture()
        }
        commandEncoder.setTexture(noiseTexture, index: 2)
    }
    
    public override var input: Input? {
        didSet {
            noiseFilter.removeAllTargets()
            noiseFilter.input = input
            if source != nil {
                noiseFilter.process()
            }
        }
    }
    
}
