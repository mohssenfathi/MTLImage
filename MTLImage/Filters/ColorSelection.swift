//
//  ColorSelection.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/13/16.
//
//

import UIKit

struct ColorSelectionUniforms: Uniforms {
    var red    : Float = 1.0;
    var orange : Float = 1.0;
    var yellow : Float = 1.0;
    var green  : Float = 1.0;
    var aqua   : Float = 1.0;
    var blue   : Float = 1.0;
    var purple : Float = 1.0;
    var magenta: Float = 1.0;
}

public
class ColorSelection: Filter {
    var uniforms = ColorSelectionUniforms()
    
    public init() {
        super.init(functionName: "colorSelection")
        title = "Color Selection"
        properties = [Property(key: "red"    , title: "Red"    ),
                      Property(key: "orange" , title: "Orange" ),
                      Property(key: "yellow" , title: "Yellow" ),
                      Property(key: "green"  , title: "Green"  ),
                      Property(key: "aqua"   , title: "Aqua"   ),
                      Property(key: "blue"   , title: "Blue"   ),
                      Property(key: "purple" , title: "Purple" ),
                      Property(key: "magenta", title: "Magenta")]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.red     = red
        uniforms.orange  = orange
        uniforms.yellow  = yellow
        uniforms.green   = green
        uniforms.aqua    = aqua
        uniforms.blue    = blue
        uniforms.purple  = purple
        uniforms.magenta = magenta
        
        updateUniforms(uniforms: uniforms)
    }
    
    
//    MARK: - Colors
    
    public var red: Float = 1.0 {
        didSet {
            clamp(&red, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var orange: Float = 1.0 {
        didSet {
            clamp(&orange, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var yellow: Float = 1.0 {
        didSet {
            clamp(&yellow, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var green: Float = 1.0 {
        didSet {
            clamp(&green, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var aqua: Float = 1.0 {
        didSet {
            clamp(&aqua, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var blue: Float = 1.0 {
        didSet {
            clamp(&blue, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var purple: Float = 1.0 {
        didSet {
            clamp(&purple, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public var magenta: Float = 1.0 {
        didSet {
            clamp(&magenta, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
}
