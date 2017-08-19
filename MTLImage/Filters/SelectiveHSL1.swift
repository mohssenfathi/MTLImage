//
//  SelectiveHSL1.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/14/16.
//
//

import UIKit

struct SelectiveHSLUniforms1 {
    var red    : Float = 0.0
    var orange : Float = 0.0
    var yellow : Float = 0.0
    var green  : Float = 0.0
    var aqua   : Float = 0.0
    var blue   : Float = 0.0
    var purple : Float = 0.0
    var magenta: Float = 0.0
    var mode   : Int   = 0
}

public
class SelectiveHSL1: Filter {
    var uniforms = SelectiveHSLUniforms1()
    
    public var mode: Int = 0 {
        didSet {
            clamp(&mode, low: 0, high: 3)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "selectiveHSL")
        title = "Selective HSL"
        properties = [Property(key: "red"    , title: "Red"    ),
                      Property(key: "orange" , title: "Orange" ),
                      Property(key: "yellow" , title: "Yellow" ),
                      Property(key: "green"  , title: "Green"  ),
                      Property(key: "aqua"   , title: "Aqua"   ),
                      Property(key: "blue"   , title: "Blue"   ),
                      Property(key: "purple" , title: "Purple" ),
                      Property(key: "magenta", title: "Magenta")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.red     = red * 20.0
        uniforms.orange  = orange
        uniforms.yellow  = yellow * 20.0
        uniforms.green   = green
        uniforms.aqua    = aqua
        uniforms.blue    = blue
        uniforms.purple  = purple
        uniforms.magenta = magenta
        uniforms.mode    = mode
        
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<SelectiveHSLUniforms1>.size, options: .cpuCacheModeWriteCombined)
    }
    
    
    //    MARK: - Colors
    
    public var red: Float = 0.0 {
        didSet {
            clamp(&red, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var orange: Float = 0.0 {
        didSet {
            clamp(&orange, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var yellow: Float = 0.0 {
        didSet {
            clamp(&yellow, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var green: Float = 0.0 {
        didSet {
            clamp(&green, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var aqua: Float = 0.0 {
        didSet {
            clamp(&aqua, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var blue: Float = 0.0 {
        didSet {
            clamp(&blue, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var purple: Float = 0.0 {
        didSet {
            clamp(&purple, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var magenta: Float = 0.0 {
        didSet {
            clamp(&magenta, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
}
