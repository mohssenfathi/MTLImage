//
//  MTLSelectiveHSL.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/13/16.
//
//

import UIKit

struct SelectiveHSLUniforms: Uniforms {
    var mode: Int = 0
}

public
class SelectiveHSL: Filter {
    var uniforms = SelectiveHSLUniforms()
    
    private var adjustmentsTexture: MTLTexture?
    private var hueAdjustments        = [Float](repeating: 0.0, count: 7)
    private var saturationAdjustments = [Float](repeating: 0.0, count: 7)
    private var luminanceAdjustments  = [Float](repeating: 0.0, count: 7)
    
    public var mode: Int = 0 {
        didSet {
            clamp(&mode, low: 0, high: 3)
            needsUpdate = true
        }
    }
    
    public var adjustments: [Float] = [Float](repeating: 0.0, count: 7) {
        didSet {
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "selectiveHSL")
        title = "Selective HSL"
        
        let modeProperty = Property(key: "mode", title: "Mode", propertyType: .selection)
        modeProperty.selectionItems = [0 : "Hue", 1 : "Saturation", 2 : "Luminance"]
        
        properties = [Property(key: "red"    , title: "Red"    ),
                      Property(key: "orange" , title: "Orange" ),
                      Property(key: "yellow" , title: "Yellow" ),
                      Property(key: "green"  , title: "Green"  ),
                      Property(key: "aqua"   , title: "Aqua"   ),
                      Property(key: "blue"   , title: "Blue"   ),
                      Property(key: "purple" , title: "Purple" ),
                      Property(key: "magenta", title: "Magenta"),
                      modeProperty]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        
        updateUniforms(uniforms: uniforms)
    }
    
    func loadColorAdjustmentTexture() {
        let adjustments = hueAdjustments + saturationAdjustments + luminanceAdjustments
        let size = adjustments.count
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: size, height: 1, mipmapped: false)
        self.adjustmentsTexture = self.device.makeTexture(descriptor: textureDescriptor)
        self.adjustmentsTexture!.replace(region: MTLRegionMake2D(0, 0, size, 1), mipmapLevel: 0, withBytes: adjustments, bytesPerRow: MemoryLayout<Float>.size * size)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        if needsUpdate == true {
            loadColorAdjustmentTexture()
        }
        commandEncoder.setTexture(adjustmentsTexture, index: 2)
    }
    
    func updateColor(_ value: Float, index: Int) {
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
            needsUpdate = true
            updateColor(red, index: 0)
        }
    }
    
    public var orange: Float = 0.0 {
        didSet {
            clamp(&orange, low: 0, high: 1)
            needsUpdate = true
            updateColor(orange, index: 1)
        }
    }
    
    public var yellow: Float = 0.0 {
        didSet {
            clamp(&yellow, low: 0, high: 1)
            needsUpdate = true
            updateColor(yellow, index: 2)
        }
    }
    
    public var green: Float = 0.0 {
        didSet {
            clamp(&green, low: 0, high: 1)
            needsUpdate = true
            updateColor(green, index: 3)
        }
    }
    
    public var aqua: Float = 0.0 {
        didSet {
            clamp(&aqua, low: 0, high: 1)
            needsUpdate = true
            updateColor(orange, index: 4)
        }
    }
    
    public var blue: Float = 0.0 {
        didSet {
            clamp(&blue, low: 0, high: 1)
            needsUpdate = true
            updateColor(blue, index: 5)
        }
    }
    
    public var purple: Float = 0.0 {
        didSet {
            clamp(&purple, low: 0, high: 1)
            needsUpdate = true
            updateColor(purple, index: 6)
        }
    }
    
    public var magenta: Float = 0.0 {
        didSet {
            clamp(&magenta, low: 0, high: 1)
            needsUpdate = true
            updateColor(magenta, index: 7)
        }
    }
}
