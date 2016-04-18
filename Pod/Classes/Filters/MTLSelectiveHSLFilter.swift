//
//  MTLSelectiveHSL.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/13/16.
//
//

import UIKit

struct SelectiveHSLUniforms {
    var mode: Int = 0
}

public
class MTLSelectiveHSLFilter: MTLFilter {
    var uniforms = SelectiveHSLUniforms()
    
    private var adjustmentsTexture: MTLTexture?
    private var hueAdjustments        = [Float](count: 7, repeatedValue: 0.0)
    private var saturationAdjustments = [Float](count: 7, repeatedValue: 0.0)
    private var luminanceAdjustments  = [Float](count: 7, repeatedValue: 0.0)
    
    public var mode: Int = 0 {
        didSet {
            clamp(&mode, low: 0, high: 3)
            dirty = true
            update()
        }
    }
    
    public var adjustments: [Float] = [Float](count: 7, repeatedValue: 0.0) {
        didSet {
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "selectiveHSL")
        title = "Selective HSL"
        
        let modeProperty = MTLProperty(key: "mode", title: "Mode", type: Int(), propertyType: .Selection)
        modeProperty.selectionItems = [0 : "Hue", 1 : "Saturation", 2 : "Luminance"]
        
        properties = [MTLProperty(key: "red"    , title: "Red"    ),
                      MTLProperty(key: "orange" , title: "Orange" ),
                      MTLProperty(key: "yellow" , title: "Yellow" ),
                      MTLProperty(key: "green"  , title: "Green"  ),
                      MTLProperty(key: "aqua"   , title: "Aqua"   ),
                      MTLProperty(key: "blue"   , title: "Blue"   ),
                      MTLProperty(key: "purple" , title: "Purple" ),
                      MTLProperty(key: "magenta", title: "Magenta"),
                      modeProperty]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        
//        uniforms.red     = red * 20.0
//        uniforms.orange  = orange
//        uniforms.yellow  = yellow * 20.0
//        uniforms.green   = green
//        uniforms.aqua    = aqua
//        uniforms.blue    = blue
//        uniforms.purple  = purple
//        uniforms.magenta = magenta
        uniforms.mode = mode
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(SelectiveHSLUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    func loadColorAdjustmentTexture() {
        let adjustments = hueAdjustments + saturationAdjustments + luminanceAdjustments
        let size = adjustments.count
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: 1, mipmapped: false)
        self.adjustmentsTexture = self.device.newTextureWithDescriptor(textureDescriptor)
        self.adjustmentsTexture!.replaceRegion(MTLRegionMake2D(0, 0, size, 1), mipmapLevel: 0, withBytes: adjustments, bytesPerRow: sizeof(Float) * size)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if dirty == true {
            loadColorAdjustmentTexture()
        }
        commandEncoder.setTexture(adjustmentsTexture, atIndex: 2)
    }
    
    func updateColor(value: Float, index: Int) {
        switch mode {
        case 0: hueAdjustments[index] = value
            break
        case 0: saturationAdjustments[index] = value
            break
        case 0: luminanceAdjustments[index] = value
            break
        default: break
        }
    }
    
    //    MARK: - Colors
    
    public var red: Float = 0.0 {
        didSet {
            clamp(&red, low: 0, high: 1)
            dirty = true
            updateColor(red, index: 0)
        }
    }
    
    public var orange: Float = 0.0 {
        didSet {
            clamp(&orange, low: 0, high: 1)
            dirty = true
            updateColor(orange, index: 1)
        }
    }
    
    public var yellow: Float = 0.0 {
        didSet {
            clamp(&yellow, low: 0, high: 1)
            dirty = true
            updateColor(yellow, index: 2)
        }
    }
    
    public var green: Float = 0.0 {
        didSet {
            clamp(&green, low: 0, high: 1)
            dirty = true
            updateColor(green, index: 3)
        }
    }
    
    public var aqua: Float = 0.0 {
        didSet {
            clamp(&aqua, low: 0, high: 1)
            dirty = true
            updateColor(orange, index: 4)
        }
    }
    
    public var blue: Float = 0.0 {
        didSet {
            clamp(&blue, low: 0, high: 1)
            dirty = true
            updateColor(blue, index: 5)
        }
    }
    
    public var purple: Float = 0.0 {
        didSet {
            clamp(&purple, low: 0, high: 1)
            dirty = true
            updateColor(purple, index: 6)
        }
    }
    
    public var magenta: Float = 0.0 {
        didSet {
            clamp(&magenta, low: 0, high: 1)
            dirty = true
            updateColor(magenta, index: 7)
        }
    }
}