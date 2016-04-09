//
//  MTLWaterFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/9/16.
//
//

import UIKit

struct WaterUniforms {
    var time: Float = 0.0
    var speed: Float = 0.5
    var frequency: Float = 0.5
    var intensity: Float = 0.5
    var emboss: Float = 0.5
    var delta: Float = 0.5
    var intence: Float = 0.5
}

public
class MTLWaterFilter: MTLFilter {
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
        properties = [MTLProperty(key: "speed",     title: "Speed", type: Float()),
                      MTLProperty(key: "frequency", title: "Frequency", type: Float()),
                      MTLProperty(key: "intensity", title: "Intensity", type: Float()),
                      MTLProperty(key: "emboss",    title: "Enboss", type: Float()),
                      MTLProperty(key: "delta",     title: "Delta", type: Float()),
                      MTLProperty(key: "intence",   title: "Intence", type: Float())]
        update()
    }
    
    public override func process() {
        update()
        super.process()
        dirty = true
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
        
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(WaterUniforms), options: .CPUCacheModeDefaultCache)
    }

}
