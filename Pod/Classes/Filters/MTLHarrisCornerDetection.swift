//
//  MTLHarrisCornerDetectionFilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

public
class MTLHarrisCornerDetectionFilterGroup: MTLFilterGroup {

    public var corners = [CGPoint]()
    
//    Temp
    public var cornerView: UIView?
    
    let derivativeFilter = MTLXYDerivativeFilter()
    let blurFilter = MTLGaussianBlurFilter()
    let harrisCornerDetectionFilter = MTLHarrisCornerDetectionFilter()
    let nonMaximumSuppressionFilter = MTLNonMaximumSuppressionFilter()
    var outputFilter = MTLHarrisCornerDetectionOutputFilter()
    
    override init() {
        super.init()
        
        title = "Harris Corner Detection"
        
        derivativeFilter.edgeStrength = 1.0
        blurFilter.blurRadius = 0.1
        harrisCornerDetectionFilter.sensitivity = 1.0
        
        add(derivativeFilter)
        add(blurFilter)
        add(harrisCornerDetectionFilter)
        add(nonMaximumSuppressionFilter)
        add(outputFilter)
        
        cornerView = UIView()
        cornerView?.backgroundColor = UIColor.clearColor()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateCorners() {
        guard let outputTexture = nonMaximumSuppressionFilter.texture else {
            return
        }
        
        let textureSize = CGSize(width: outputTexture.width, height: outputTexture.height)
        let width:Int = Int(textureSize.width)
        let height: Int = Int(textureSize.height)
        
        let byteCount: Int = width * height * 4
        let bytes = UnsafeMutablePointer<uint_fast8_t>(malloc(byteCount))
        let bytesPerRow = width * 4
        
        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        outputTexture.getBytes(bytes, bytesPerRow: bytesPerRow, fromRegion: region, mipmapLevel: 0)
        
        corners.removeAll()
        
        var currentByte: Int = 0
        var cornerStorageIndex = 0
        while (currentByte < byteCount) {
            
            let colorByte = bytes[currentByte]
            
            if (colorByte > 0) {
                let x = CGFloat(currentByte) % textureSize.width
                let y = CGFloat(currentByte) / textureSize.width
                
                let point = CGPoint(x: x/4, y: y)
                corners.append(point)
            }
            
            currentByte = currentByte + 4
        }
        
        free(bytes)
        
        outputFilter.originalTexture = input?.texture
    }
    
    public override var texture: MTLTexture? {
        get {
            return input?.texture
        }
    }
    
    public override var needsUpdate: Bool {
        didSet {
            updateCorners()
        }
    }
    
    
    
//    Temp
    
    func drawCorner(point: CGPoint) {
        let corner = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        corner.backgroundColor = UIColor.redColor()
        corner.layer.masksToBounds = true
        corner.layer.cornerRadius = 2.5
        corner.center = point
        cornerView!.addSubview(corner)
    }
}


// Output Filter

struct HarrisCornerDetectionOutputUniforms {
    
}

public
class MTLHarrisCornerDetectionOutputFilter: MTLFilter {
    
    var uniforms = HarrisCornerDetectionOutputUniforms()
    private var originalTexture: MTLTexture?
    
    public init() {
        super.init(functionName: "harrisCornerDetectionOutput")
        title = "Harris Corner Detection Output"
        properties = []
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(HarrisCornerDetectionOutputUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        commandEncoder.setTexture(originalTexture, atIndex: 2)
    }
}
