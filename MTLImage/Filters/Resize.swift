//
//  Resize.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/12/17.
//

import MetalPerformanceShaders

public
class Resize: MPS {
    
    var outputSize: MTLSize? = nil {
        didSet { needsUpdate = true }
    }
    private var internalOutputSize: MTLSize? {
        
        if let outputSize = outputSize {
            return outputSize
        }
        
        if let target = targets.first as? MTLObject,
            let width = target.texture?.width,
            let height = target.texture?.height,
            let depth = target.texture?.depth {
            return MTLSize(width: width, height: height, depth: depth)
        }
        
        if let width = input?.texture?.width,
            let height = input?.texture?.height {
            return MTLSize(width: width, height: height, depth: 1)
        }
        
        return nil
    }
    
    public init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func commonInit() {
        title = "Resize"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        super.update()
        
        guard let inputSize = input?.texture?.size(), let outputSize = internalOutputSize else { return }
        
        let scaleX = Double(outputSize.width) / Double(inputSize.width)
        let scaleY = Double(outputSize.height) / Double(inputSize.height)
        let translateX = 0.0
        let translateY = 0.0
        let filter = MPSImageLanczosScale(device: device)
        var transform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            filter.scaleTransform = transformPtr
            //            filter.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destTexture)
        }
        
        kernel = filter
    }
    
    public override var input: Input? {
        didSet {
            if let cam = source as? Camera {
                outputSize = cam.texture?.size()
            }
            
            if let inputTexture = input?.texture, let size = outputSize {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat,
                                                                                 width: size.width,
                                                                                 height: size.height,
                                                                                 mipmapped: false)
                texture = context.device?.makeTexture(descriptor: textureDescriptor)
            }
            reload()
        }
    }
}



























public
class Resize1: Filter {
    
    var outputSize: MTLSize?
    private var internalOutputSize: MTLSize? {
        
        if let outputSize = outputSize {
            return outputSize
        }
        
        if let target = targets.first as? MTLObject,
            let width = target.texture?.width,
            let height = target.texture?.height,
            let depth = target.texture?.depth {
            return MTLSize(width: width, height: height, depth: depth)
        }
        
        if let width = input?.texture?.width,
            let height = input?.texture?.height {
            return MTLSize(width: width, height: height, depth: 1)
        }
        
        return nil
    }
    
    public init() {
        super.init(functionName: "resize")
        title = "Resize"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var input: Input? {
        didSet {
            
            if let inputTexture = input?.texture, let size = outputSize {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat,
                                                                                 width: size.width,
                                                                                 height: size.height,
                                                                                 mipmapped: false)
                
                texture = context.device?.makeTexture(descriptor: textureDescriptor)
            }
            
            reload()
        }
    }
}
