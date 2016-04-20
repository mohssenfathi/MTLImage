//
//  MTLMaskFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/16/16.
//
//

import UIKit

struct MaskUniforms {
    var brushSize: Float = 0.25
    var x: Float = 0.5
    var y: Float = 0.5
}

public
class MTLMaskFilter: MTLFilter {
    var uniforms = MaskUniforms()
    
    private var viewSize: CGSize?
    private var imageSize: CGSize?
    private var maskTexture: MTLTexture?
    private var originalTexture: MTLTexture?
    private var mask: [Float]?
    private var width: Int = 1000
    private var lastPoint: CGPoint?
    
    public var brushSize: Float = 0.25 {
        didSet {
            clamp(&brushSize, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
//    public var add: CGPoint = CGPointZero {
//        didSet {
//            updateMask(add, value: 1.0) // Add a bool property later for this
//            dirty = true
//        }
//    }
    
    public var point: CGPoint = CGPointZero {
        didSet {
            
            lastPoint = oldValue
            if distance(oldValue, point2: point) > 20  { lastPoint = nil }
            
            if viewSize != nil {
                clamp(&point.x, low: 0, high: viewSize!.width)
                clamp(&point.y, low: 0, high: viewSize!.height)
            }
            updateMask(point, value: 0.0)
            originalTexture = nil
            dirty = true
            update()
        }
    }
    
    public override func reset() {
        mask = [Float](count: width * width, repeatedValue: 1.0)
        point = CGPointZero
        update()
    }
    
    func updateMask(point: CGPoint, value: Float) {  // recieves point relative to output view
        // Change to generics later
        if viewSize == nil { return }
        
        let radius = CGFloat(brushSize * 50.0)
        
        let cx = Tools.convert(point.x, oldMin: 0.0, oldMax: viewSize!.height, newMin: 1.0, newMax: CGFloat(width))
        let cy = Tools.convert(point.y, oldMin: 0.0, oldMax: viewSize!.width, newMin: 1.0, newMax: CGFloat(width))
        
        if lastPoint != nil {
            let lx = Tools.convert(lastPoint!.x, oldMin: 0.0, oldMax: viewSize!.width , newMin: 0.0, newMax: CGFloat(width))
            let ly = Tools.convert(lastPoint!.y, oldMin: 0.0, oldMax: viewSize!.height, newMin: 0.0, newMax: CGFloat(width))
            
            let dx = fabs(lx - cx)
            let dy = fabs(ly - cy)
//            let dy2 = 2 * dy
//            let dydx2 = (dy2 - (2 * dx))
            let m = dy/dx
//            let b = ly - m * lx

            let xDir: CGFloat = cx > lx ? 1.0 : -1.0
            let yDir: CGFloat = cy > ly ? 1.0 : -1.0
            
            var x = lx
            var y = ly
            
            if m < 1.0 {
                while (xDir > 0 && x <= cx) || (xDir < 0 && x >= cx) {
                    clearPoint(CGPoint(x: x, y: round(y)), radius: radius)
                    x += radius/2 * xDir
                    y += radius/2 * m
                }
            }
            else {
                clearPoint(CGPoint(x: round(x), y: y), radius: radius)
                y += radius/2 * yDir
                x += (radius/2 * xDir)/m
            }
        }
        else {
            clearPoint(CGPoint(x: cx, y: cy), radius: radius)
        }
    }
    
    func clearPoint(point: CGPoint, radius: CGFloat) {
        var starti = Int(point.x - radius)
        var startj = Int(point.y - radius)
        var endi   = Int(point.x + radius)
        var endj   = Int(point.y + radius)
        
        clamp(&starti, low: 0, high: width)
        clamp(&startj, low: 0, high: width)
        clamp(&endi  , low: 0, high: width)
        clamp(&endj  , low: 0, high: width)
        
        var currentValue: CGFloat!
        for i in starti ..< endi {
            for j in startj ..< endj {
                let dist = distance(CGPoint(x: i, y: j), point2: point)
                if dist < radius {
                    currentValue = CGFloat(mask![j * width + i])
                    mask![j * width + i] = Float(min(pow(dist/radius, 2), currentValue)) //do max if add
                }
            }
        }
    }
    
    func distance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    public init() {
        super.init(functionName: "mask")
        title = "Mask"
        properties = [MTLProperty(key: "brushSize", title: "Brush Size"),
                      MTLProperty(key: "point"    , title: "Point"     , type: CGPoint(), propertyType: .Point)]
        mask = [Float](count: width * width, repeatedValue: 1.0)
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
        if originalTexture == nil {
            if let inputFilter = input as? MTLFilter {
                if inputFilter.input != nil {
                    originalTexture = inputFilter.input?.texture
                }
                else {
                    originalTexture = inputFilter.texture
                }
            } else if let sourcePicture = input as? MTLPicture {
                originalTexture = sourcePicture.texture
            }
        }
        
        if imageSize != nil && viewSize != nil {
            uniforms.x = Float(Tools.convert(Float(point.x), oldMin: 0, oldMax: Float(viewSize!.width),
                                                             newMin: 0, newMax: Float(imageSize!.width))/Float(imageSize!.width))
            uniforms.y = Float(Tools.convert(Float(point.y), oldMin: 0, oldMax: Float(viewSize!.height),
                                                             newMin: 0, newMax: Float(imageSize!.height))/Float(imageSize!.height))
        }
        
        if viewSize == nil {
            if let mtlView = outputView {
                viewSize = mtlView.frame.size
            }
        }
        
        uniforms.brushSize = brushSize * 100
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(MaskUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        if dirty == true {
            updateMaskTexture()
        }
        commandEncoder.setTexture(maskTexture, atIndex: 2)
        commandEncoder.setTexture(originalTexture, atIndex: 3)
    }
    
    func updateMaskTexture() {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: width, height: width, mipmapped: false)
        maskTexture = self.device.newTextureWithDescriptor(textureDescriptor)
        maskTexture!.replaceRegion(MTLRegionMake2D(0, 0, width, width), mipmapLevel: 0, withBytes: mask!, bytesPerRow: sizeof(Float) * width)
    }
    
    override public var input: MTLInput? {
        didSet {
            imageSize = originalImage?.size
        }
    }
    
}