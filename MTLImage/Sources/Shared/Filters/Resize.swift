//
//  Resize.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/12/17.
//

import MetalPerformanceShaders

public
class Resize: MPS {
    
    public var outputSize: MTLSize? = nil {
        didSet { needsUpdate = true }
    }
//    private var internalOutputSize: MTLSize? {
//
//        if let outputSize = outputSize {
//            return outputSize
//        }
//
//        if let target = targets.first as? MTLObject,
//            let width = target.texture?.width,
//            let height = target.texture?.height,
//            let depth = target.texture?.depth {
//            return MTLSize(width: width, height: height, depth: depth)
//        }
//
//        if let width = input?.texture?.width,
//            let height = input?.texture?.height {
//            return MTLSize(width: width, height: height, depth: 1)
//        }
//
//        return nil
//    }
    
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
    
    override public func update() {
        super.update()
        
        guard let inputSize = input?.texture?.size(), let outputSize = outputSize else { return }
        
        
        if let currentSize = texture?.size() {
            if currentSize.width != outputSize.width || currentSize.height != outputSize.height {
                initTexture()
            }
        }
        
        let scaleX = Double(outputSize.width) / Double(inputSize.width)
        let scaleY = Double(outputSize.height) / Double(inputSize.height)
        let translateX = 0.0
        let translateY = 0.0
        let filter = MPSImageLanczosScale(device: device)
        var transform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        
        withUnsafePointer(to: &transform) { filter.scaleTransform = $0 }
        
        kernel = filter
    }
    
    override func initTexture() {
        
        // Overriding to set texture size to outputSize
        
        if outputSize == nil {
            outputSize = input?.texture?.size()
        }
        
        if let inputTexture = input?.texture, let size = outputSize {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat,
                                                                             width: size.width,
                                                                             height: size.height,
                                                                             mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            texture = context.device?.makeTexture(descriptor: textureDescriptor)
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
