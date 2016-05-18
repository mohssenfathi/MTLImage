//
//  MTLCropFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/12/16.
//
//

import UIKit

struct CropUniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
    var fit: Int = 1
}

public
class MTLCropFilter: MTLFilter {
    
    var uniforms = CropUniforms()
   
    public var fit: Bool = true {
        didSet {
            needsUpdate = true
            update()
        }
    }
    
    public var x: Float = 0.0 {
        didSet {
            if x + width > 1.0 { x = oldValue }
            needsUpdate = true
            update()
        }
    }
    
    public var y: Float = 0.0 {
        didSet {
            if y + height > 1.0 { y = oldValue }
            needsUpdate = true
            update()
        }
    }
    
    public var width: Float = 1.0 {
        didSet {
            if x + width > 1.0 { width = oldValue }
            needsUpdate = true
            update()
        }
    }
    
    public var height: Float = 1.0 {
        didSet {
            if y + height > 1.0 { height = oldValue }
            needsUpdate = true
            update()
        }
    }
    
//    public var cropRegion: CGRect = CGRect(x: 0, y: 0, width: 1, height: 0.5) {
//        didSet {
//            assert(cropRegion.size.width  <= 1.0)
//            assert(cropRegion.size.height <= 1.0)
//            assert(cropRegion.origin.x    >= 0.0)
//            assert(cropRegion.origin.y    >= 0.0)
//            
//            needsUpdate = true
//            update()
//        }
//    }
    
    public init() {
        super.init(functionName: "crop")
        title = "Crop"
//        properties = [MTLProperty(key: "cropRegion", title: "Crop Region", propertyType: .Rect)]
        properties = [MTLProperty(key: "x", title: "X"),
                      MTLProperty(key: "y", title: "Y"),
                      MTLProperty(key: "width", title: "Width"),
                      MTLProperty(key: "height", title: "Height"),
                      MTLProperty(key: "fit", title: "Fit", propertyType: .Bool)]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        
        uniforms.x = x
        uniforms.y = y
        uniforms.width = width
        uniforms.height = height
        uniforms.fit = fit ? 1 : 0
        
//        uniforms.x = Float(cropRegion.origin.x)
//        uniforms.y = Float(cropRegion.origin.y)
//        uniforms.width = Float(cropRegion.size.width)
//        uniforms.height = Float(cropRegion.size.height)
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(CropUniforms), options: .CPUCacheModeDefaultCache)
    }
    
}