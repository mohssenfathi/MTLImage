//
//  Water.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/9/16.
//
//

import UIKit

struct WaterUniforms: Uniforms {
    var time: Float = 0.0
    var speed: Float = 0.5
    var frequency: Float = 0.5
    var intensity: Float = 0.5
    var emboss: Float = 0.5
    var delta: Float = 0.5
    var intence: Float = 0.5
}

public
class Water: Filter {
    var uniforms = WaterUniforms()
    
    public var speed: Float = 0.5 {
        didSet {
            clamp(&speed, low: 0, high: 1)
        }
    }
    
    public var frequency: Float = 0.5 {
        didSet {
            clamp(&frequency, low: 0, high: 1)
        }
    }
    
    public var intensity: Float = 0.5 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
        }
    }
    
    public var emboss: Float = 0.5 {
        didSet {
            clamp(&emboss, low: 0, high: 1)
        }
    }
    
    public var delta: Float = 0.5 {
        didSet {
            clamp(&delta, low: 0, high: 1)
        }
    }
    
    public var intence: Float = 0.5 {
        didSet { clamp(&intence, low: 0, high: 1) }
    }
    
    public init() {
        super.init(functionName: "water")
        title = "Water"
        properties = [Property(key: "speed",     title: "Speed"    ),
                      Property(key: "frequency", title: "Frequency"),
                      Property(key: "intensity", title: "Intensity"),
                      Property(key: "emboss",    title: "Enboss"   ),
                      Property(key: "delta",     title: "Delta"    ),
                      Property(key: "intence",   title: "Intence"  )]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func process() {
        update()
        super.process()
        needsUpdate = true
    }
    
    override func update() {
        if self.input == nil { return }
    
        uniforms.speed = speed * 0.5 + 0.1
        uniforms.intensity = Tools.convert(intensity, oldMin: 0, oldMax: 1, newMin: 2.0, newMax: 6.0)
        uniforms.emboss = emboss + 0.5
        uniforms.frequency = frequency * 6.0 + 3.0
        uniforms.delta = delta * 60.0 + 30.0
        uniforms.intence = intence * 500.0 + 400.0
        uniforms.time += 1.0/60.0
        
        updateUniforms(uniforms: uniforms)
    }
    
    override public var continuousUpdate: Bool {
        return true
    }
}
