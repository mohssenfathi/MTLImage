//
//  Mask.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/19/16.
//
//

struct MaskUniforms: Uniforms {
    var brushSize: Float = 0.25
    var x: Float = 0.5
    var y: Float = 0.5
}

public
class Mask: Filter {

    var uniforms = MaskUniforms()
    
    public var brushSize: Float = 0.25 {
        didSet {
            clamp(&brushSize, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var hardness: Float = 0.5 {
        didSet {
            clamp(&hardness, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var point: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            clamp(&point.x, low: 0.0, high: 1.0)
            clamp(&point.y, low: 0.0, high: 1.0)
            needsUpdate = true
        }
    }
    
    public var add: Bool = false {
        didSet {
            needsUpdate = true
        }
    }
 
    
    public init() {
        super.init(functionName: "mask")
        
        title = "Mask"
        
        properties = [Property(key: "point"    , title: "Point"      , propertyType: .point),
                      Property(key: "add"      , title: "Add"        , propertyType: .bool),
                      Property(key: "brushSize", title: "Brush Size"),
                      Property(key: "hardness" , title: "Hardness"  )]
                      
        
        mask = [Float](repeating: 1.0, count: Int(size.width * size.height))
            //[[Float]](repeating: [Float](repeating: 1.0, count: Int(size.width)), count: Int(size.height))
        
        update()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
     
        if needsUpdate == true {
            updateMaskTexture()
        }
        
        commandEncoder.setTexture(maskTexture, index: 2)
        commandEncoder.setTexture(originalTexture, index: 3)
    }
    
    func updateMaskTexture() {
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float,
                                                                         width: Int(size.width),
                                                                         height: Int(size.height),
                                                                         mipmapped: false)
        
        maskTexture = self.device.makeTexture(descriptor: textureDescriptor)
        
        maskTexture!.replace(region: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)),
                             mipmapLevel: 0,
                             withBytes: mask,
                             bytesPerRow: MemoryLayout<Float>.size * Int(size.width))
    }
    
    override func update() {
        super.update()
        
        // TODO: Move this inside the shader later
        
        let radius = CGFloat(brushSize / 4.0)
        clearPoint(point, radius: radius)
        
//        var minX = max(0     , Int((point.x - radius) * size.width))
//        let maxX = min(width , Int((point.x + radius) * size.width))
//        var minY = max(0     , Int((point.y - radius) * size.height))
//        let maxY = max(height, Int((point.y + radius) * size.height))
//        
//        let x = Int(point.x) * width
//        let y = Int(point.y) * height
//        
//        let value: Float = mask[y][x]
//        let change = add ? (1.0 - value) * hardness : -(value * hardness)
//        
//        for i in minY ..< maxY {
//            for j in minX ..< maxX {
//                
//                mask[i][j] += change
//                clamp(&mask[i][j], low: 0.0, high: 1.0)
//                
//            }
//        }
    }
    
    func clearPoint(_ point: CGPoint, radius: CGFloat) {
        
        let width  = Int(size.width)
        let height = Int(size.height)

        
        var starti = Int(point.x - radius)
        var startj = Int(point.y - radius)
        var endi   = Int(point.x + radius)
        var endj   = Int(point.y + radius)
        
        clamp(&starti, low: 0, high: width)
        clamp(&startj, low: 0, high: height)
        clamp(&endi  , low: 0, high: width)
        clamp(&endj  , low: 0, high: height)
        
        var currentValue: CGFloat!
        for i in starti ..< endi {
            for j in startj ..< endj {
                let dist = distance(CGPoint(x: i, y: j), point2: point)
                if dist < radius {
                    currentValue = CGFloat(mask[j * width + i])
                    mask[j * width + i] = Float(min(pow(dist/radius, 2), currentValue)) //do max if add
                }
            }
        }
    }
    
    func distance(_ point1: CGPoint, point2: CGPoint) -> CGFloat {
        return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    
    override func reload() {
        super.reload()
        
        if let texture = input?.texture {
            size = CGSize(width: texture.width, height: texture.height)
        }
    }
    
    
    
    // MARK: - Support
    
    /** 
        A mask of Floats to determine output textures opacity
     */
    var mask: [Float]! //[[Float]]!
    
    
    /** 
        Size of the mask. Recalculate in reload()
     */
    var size: CGSize = CGSize(width: 500, height: 500) //{
//        didSet {
//            mask = [[Float]](repeating: [Float](repeating: 1.0, count: Int(size.width)), count: Int(size.height))
//        }
//    }
    
    
    private var maskTexture: MTLTexture?
    private var originalTexture: MTLTexture?
}
