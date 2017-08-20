//
//  RollingAverage.swift
//  MTLImage-iOS10.0
//
//  Created by Mohssen Fathi on 6/15/17.
//

public
class RollingAverage: Filter {
    
    var textureQueue = [MTLTexture]()
    
    private var uniforms = RollingAverageUniforms()
    private struct RollingAverageUniforms: Uniforms {
        var bufferLength: Float = 10
        var currentBufferCount: Float = 0
    }
    
    public init() {
        super.init(functionName: "rollingAverage")
        title = "Rolling Average"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        super.update()
        uniforms.currentBufferCount = Float(textureQueue.count)
        updateUniforms(uniforms: uniforms)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        guard let texture = texture else { return }
        
        textureQueue.append(texture.copy(device: device))
        
        commandEncoder.setTexture(textureQueue.first, index: 2)
        commandEncoder.setTexture(textureQueue.last, index: 3)
        
        if textureQueue.count > bufferLength {
            textureQueue.remove(at: 0)
        }
    }
    
    // MARK: - Properties
    public var bufferLength: Int = 10 {
        didSet {
            uniforms.bufferLength = Float(bufferLength)
            needsUpdate = true
        }
    }
}
