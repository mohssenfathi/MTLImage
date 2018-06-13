//
//  MTLSelectiveHSL.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/13/16.
//
//

import Metal
import MetalKit

struct SelectiveHSLUniforms: Uniforms {
    var red: float3 = float3(0, 1, 1)
    var orange: float3 = float3(0, 1, 1)
    var yellow: float3 = float3(0, 1, 1)
    var green: float3 = float3(0, 1, 1)
    var aqua: float3 = float3(0, 1, 1)
    var blue: float3 = float3(0, 1, 1)
    var purple: float3 = float3(0, 1, 1)
    var magenta: float3 = float3(0, 1, 1)
}

public
class SelectiveHSL: Filter {
    var uniforms = SelectiveHSLUniforms()
    
    public init() {
        super.init(functionName: "selectiveHSL")
        title = "Selective HSL"
        
        let defaultValue = float3(x: 0, y: 1, z: 1)
        
        let modeProperty = Property(key: "mode", title: "Mode", propertyType: .selection)
        modeProperty.selectionItems = [0 : "Hue", 1 : "Saturation", 2 : "Luminance"]
        
        properties = [modeProperty]
        for color in Color.all {
            properties.append(Property(key: color.rawValue, title: color.rawValue.capitalized))
            values[color] = defaultValue
        }
        
        uniforms.red     = defaultValue
        uniforms.orange  = defaultValue
        uniforms.yellow  = defaultValue
        uniforms.green   = defaultValue
        uniforms.aqua    = defaultValue
        uniforms.blue    = defaultValue
        uniforms.purple  = defaultValue
        uniforms.magenta = defaultValue
        
        update()
    }
    
    public override func update() {
        super.update()
        
        let defaultValue = float3(x: 0, y: 1, z: 1)
        
        uniforms.red        = values[.red] ?? defaultValue
        uniforms.orange     = values[.orange] ?? defaultValue
        uniforms.yellow     = values[.yellow] ?? defaultValue
        uniforms.green      = values[.green] ?? defaultValue
        uniforms.aqua       = values[.aqua] ?? defaultValue
        uniforms.blue       = values[.blue] ?? defaultValue
        uniforms.purple     = values[.purple] ?? defaultValue
        uniforms.magenta    = values[.magenta] ?? defaultValue
        
        updateUniforms(uniforms: uniforms)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    @objc public var mode: Int = 0 {
        didSet {
            clamp(&mode, low: 0, high: 3)
            needsUpdate = true
        }
    }
    
    //    MARK: - Colors
    @objc public var red: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var orange: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var yellow: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var green: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var aqua: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var blue: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var purple: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    @objc public var magenta: Float = 0.5 {
        didSet { needsUpdate = true }
    }
    
    public func value(for color: Color) -> float3 {
        return values[color] ?? float3(x: 0, y: 1, z: 1)
    }
    
    public func value(for color: Color, mode: Int) -> Float {
        switch mode {
        case 0:
            if let value = values[color]?.x {
                // TODO: Check this
                return Tools.convert(value, oldMin: -(30.0/60.0), oldMax: (30.0/60.0), newMin: 0, newMax: 1)
            } else {
                return 0.5
            }
        case 1: return (values[color]?.y ?? 1.0)/2.0
        case 2: return (values[color]?.z ?? 1.0)/2.0
        default:
            return 0.0
        }
    }
    
    public func setValue(_ value: Float, for color: Color, mode: Int) {
        updateUniforms(with: value, color: color, mode: mode)
    }
    
    func updateUniforms(with value: Float, color: Color, mode: Int) {
        var value = value
        clamp(&value, low: 0, high: 1)
        
        if mode == 1 || mode == 2 {
            value *= 2.0
        }
        
        let hueRange: Float = (60.0/360.0)
        
        switch mode {
        case 0: values[color]?.x = Tools.convert(value, oldMin: 0, oldMax: 1, newMin: -hueRange, newMax: hueRange)
        case 1: values[color]?.y = value
        case 2: values[color]?.z = value
        default:
            return
        }
        
        let val = values[color] ?? float3(x: 0.5, y: 1, z: 1)
        
        switch color {
        case .red:      uniforms.red = val
        case .orange:   uniforms.orange = val
        case .yellow:   uniforms.yellow = val
        case .green:    uniforms.green = val
        case .aqua:     uniforms.aqua = val
        case .blue:     uniforms.blue = val
        case .purple:   uniforms.purple = val
        case .magenta:  uniforms.magenta = val
        }
        
        needsUpdate = true
    }
    
    public
    enum Color: String {
        case red
        case orange
        case yellow
        case green
        case aqua
        case blue
        case purple
        case magenta
        
        public var hueKey: String          { return rawValue + "Hue" }
        public var saturationKey: String   { return rawValue + "Saturation" }
        public var luminanceKey: String    { return rawValue + "Luminance" }
        
        public var hue: CGFloat {
            switch self {
            case .red:      return 0.0
            case .orange:   return 30.0
            case .yellow:   return 60.0
            case .green:    return 120.0
            case .aqua:     return 180.0
            case .blue:     return 240.0
            case .purple:   return 270.0
            case .magenta:  return 300.0
            }
        }
        
        public static var all: [Color] = [.red, .orange, .yellow, .green, .aqua, .blue, .purple, .magenta]
    }
    
    private var values: [Color : float3] = [:]
}

extension SelectiveHSL {
    
    public override func copy() -> Any {
        let filter = SelectiveHSL()
        filter.values = values
        filter.update()
        return filter
    }
}
