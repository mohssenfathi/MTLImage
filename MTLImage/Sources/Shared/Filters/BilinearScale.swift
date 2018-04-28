//
//  BilinearScale.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

import MetalPerformanceShaders

@available(iOS 11.0, *)
class BilinearScale: ImageScale<MPSImageBilinearScale> {
    
    override func configure() {
        title = "Bilinear Scale"
        properties = []
    }
}


@available(iOS 11.0, *)
public class ImageScale<S: MPSImageScale>: MPS {

    typealias ScaleFilter = S
    
    public var contentMode: UIViewContentMode = .scaleToFill {
        didSet { needsUpdate = true }
    }
    
    public var outputSize: MTLSize? = nil {
        didSet { needsUpdate = true }
    }
    
    public init() {
        super.init(functionName: nil)
        configure()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        configure()
    }
    
    func configure() {
        title = "Scale"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func update() {
        super.update()
        
        guard let inputSize = input?.texture?.size, let outputSize = outputSize else { return }
        
        if let currentSize = texture?.size {
            if currentSize.width != outputSize.width || currentSize.height != outputSize.height {
                initTexture()
            }
        }
        
        var transform = scaleTransform(inputSize: inputSize, outputSize: outputSize)
        let filter = ScaleFilter(device: device)
        
        withUnsafePointer(to: &transform) { filter.scaleTransform = $0 }
        
        kernel = filter
    }
    
    
    func scaleTransform(inputSize: MTLSize, outputSize: MTLSize) -> MPSScaleTransform {
        
        let inputRatio: Double = Double(inputSize.width) / Double(inputSize.height)
        let outputRatio: Double = Double(outputSize.width) / Double(outputSize.height)
        
        var t: (translateX: Double, translateY: Double, scaleX: Double, scaleY: Double) = (0, 0, 1, 1)
        
        switch contentMode {
        case .scaleAspectFit:
            
            // TODO: Figure out why this is clipping image
            if inputRatio > outputRatio {
                // Fit to width
                t.scaleX = Double(outputSize.width) / Double(inputSize.width)
                t.scaleY = t.scaleX
                t.translateX = 0.0
                t.translateY = (Double(outputSize.height) - (Double(outputSize.width) / inputRatio))/2.0
            } else {
                // Fit to height
                t.scaleY = Double(outputSize.height) / Double(inputSize.height)
                t.scaleX = t.scaleY
                t.translateX = (Double(outputSize.width) - (Double(outputSize.height) * inputRatio))/2.0
                t.translateY = 0.0
            }
            
        case .scaleAspectFill:
            
            if inputRatio > outputRatio {
                // Fit to height
                t.scaleY = Double(outputSize.height) / Double(inputSize.height)
                t.scaleX = t.scaleY
                t.translateX = -((Double(inputSize.width) * t.scaleX) - (Double(outputSize.width)))/2.0
                t.translateY = 0.0
            } else {
                // Fit to width
                t.scaleX = Double(outputSize.width) / Double(inputSize.width)
                t.scaleY = t.scaleX
                t.translateY = -((Double(inputSize.height) * t.scaleY) - (Double(outputSize.height)))/2.0
                t.translateX = 0.0
            }
            
        default:
            t.scaleX = Double(outputSize.width) / Double(inputSize.width)
            t.scaleY = Double(outputSize.height) / Double(inputSize.height)
            t.translateX = 0.0
            t.translateY = 0.0
        }
        
        return MPSScaleTransform(scaleX: t.scaleX, scaleY: t.scaleY, translateX: t.translateX, translateY: t.translateY)
    }
    
    override func initTexture() {
        
        // Overriding to set texture size to outputSize
        
        if outputSize == nil {
            outputSize = input?.texture?.size
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
