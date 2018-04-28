//
//  DepthProcessor.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

import MetalKit
import AVFoundation

@available(iOS 11.0, *)
public class DepthProcessor: FilterGroup {

    public var focus: Float = 0.5 {
        didSet { updateColorMatrix() }
    }
    
    private var scale: Float = 1.0
    private var inputSize: CGSize = .zero
    private var depthSize: CGSize = .zero
    private let depthRenderer = DepthRenderer()
    private let bilinearScale = BilinearScale()
//    private let minMax = MinMax()
    private let colorMatrix0 = ColorMatrix()
    private let colorMatrix1 = ColorMatrix()
    private let clamp0 = ColorClamp()
    private let clamp1 = ColorClamp()
    private let maskBlend = Blend(blendMode: .darken)
    private let blur = GaussianBlur()
    
    public override var needsUpdate: Bool {
        didSet {
            if inputSize == .zero || depthSize == .zero { configureFilters() }
        }
    }
    
    public override func reset() {
        super.reset()
        depthRenderer.reset()
    }

    override public init() {
        super.init()
        configure()
    }
    
    public func filter(image: UIImage, depthMap: CVPixelBuffer, completion: @escaping ((MTLTexture?) -> ())) {

        let picture = Picture(image: image)

        let depthProvider = TextureInput(textureProvider: { () -> (MTLTexture?) in
            return picture.texture
        })

        depthProvider.pixelBufferProvider = { () -> (CVPixelBuffer?) in
            return depthMap
        }

        depthProvider --> depthRenderer
        
        DispatchQueue.global(qos: .background).async {
            self.bilinearScale.process()
            
            DispatchQueue.main.async {
                completion(self.texture)
            }
        }
    }
    
    func configure() {
        configureFilters()
        
        blur.sigma = 0.01
        
        add(depthRenderer)
        add(blur)
        add(colorMatrix0)
        add(clamp0)
        add(maskBlend)
        add(bilinearScale)
        
        blur --> colorMatrix1 --> clamp1
        
        maskBlend.inputProvider = { [weak self] in
            return $0 == 0 ? self?.clamp1 : nil
        }
        
        //        depthRenderer --> minMax
    }
    

    func configureFilters() {
        
        guard let size = input?.texture?.cgSize, let dSize = (input as? Camera)?.depthTextureSize else {
            return
        }
        
        inputSize = size
        depthSize = dSize
        bilinearScale.outputSize = MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
//        bilinearScale.contentMode = .scaleAspectFill
        
        let maxToDim = Float(max(size.width, size.height))
        let maxFromDim = Float(max(depthSize.width, depthSize.height))
        scale = maxToDim / maxFromDim
        
        updateColorMatrix()
    }
    
    func updateColorMatrix() {
        
        let focus = self.focus * 0.9 + 0.1
        
        let slope = MaskParams.slope
        let filterWidth =  2 / slope + MaskParams.width
        let bias0 = -slope * (focus - filterWidth / 2)
        let bias1 =  slope * (focus + filterWidth / 2)
        
        colorMatrix0.red   = float4([slope, 0    , 0    , 0])
        colorMatrix0.green = float4([0    , slope, 0    , 0])
        colorMatrix0.blue  = float4([0    , 0    , slope, 0])
        colorMatrix0.bias  = float4([bias0, bias0, bias0, 0])
        
        colorMatrix1.red   = float4([-slope, 0     , 0     , 0])
        colorMatrix1.green = float4([0     , -slope, 0     , 0])
        colorMatrix1.blue  = float4([0     , 0     , -slope, 0])
        colorMatrix1.bias  = float4([bias1 , bias1 , bias1 , 0])
    }
    
    public override func process() {
        
        if inputSize == .zero || depthSize == .zero {
            configureFilters()
        }
        
        super.process()
        
//        if let contents = minMax.texture?.buffer?.contents().assumingMemoryBound(to: UInt8.self) {
//            let min = contents[0]
//            let max = contents[1]
//            print("Min: \(min)    Max: \(max)")
//        }
    }
    
    public override var input: Input? {
        didSet {
            inputSize = .zero
            depthSize = .zero
            configureFilters()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    private enum MaskParams {
        static let slope: Float = 4.0
        static let width: Float = 0.1
    }
    
    public override func copy() -> Any {
        guard let copy = super.copy() as? DepthProcessor else {
            return super.copy()
        }
        copy.configureFilters()
        return copy
    }
}

