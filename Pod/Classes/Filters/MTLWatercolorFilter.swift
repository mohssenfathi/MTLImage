//
//  MTLWatercolorFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/21/16.
//
//

import UIKit

struct WatercolorUniforms {
    var distortion: Float = 0.5
    var edgeDarkening: Float = 0.5;
    var turbulance: Float = 0.5;
}

public
class MTLWatercolorFilter: MTLFilter {
    
    var uniforms = WatercolorUniforms()
    var paperTexture: MTLTexture?
    var paperTexture2: MTLTexture?
    
    var distortion: Float = 0.5 {
        didSet {
            clamp(&distortion, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    var edgeDarkening: Float = 0.5 {
        didSet {
            clamp(&edgeDarkening, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    var turbulance: Float = 0.5 {
        didSet {
            clamp(&turbulance, low: 0, high: 1)
            dirty = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "watercolor")
        title = "Watercolor"
        properties = [MTLProperty(key: "distortion"   , title: "Distortion"),
                      MTLProperty(key: "edgeDarkening", title: "Edge Darkening"),
                      MTLProperty(key: "turbulance"   , title: "Turbulance")]
        update()
    }
    
    override func update() {
        if self.input == nil { return }
        let random: Float = Float(arc4random_uniform(100))/100.0
        uniforms.distortion = (distortion * 2 - 1) * random * 10.0
        print(uniforms.distortion)
        uniforms.edgeDarkening = edgeDarkening
        uniforms.turbulance = turbulance/2.0
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(WatercolorUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        if paperTexture == nil {
            createPaperTexture()
        }
        commandEncoder.setTexture(paperTexture , atIndex: 2)
        commandEncoder.setTexture(paperTexture2, atIndex: 3)
    }
    
    func createPaperTexture() {
        let bundle = NSBundle(forClass: MTLImage.classForCoder())
        guard let image = UIImage(named: "watercolor-paper", inBundle: bundle, compatibleWithTraitCollection: nil) else {
            return
        }
        paperTexture = image.texture(device)
        
        guard let image2 = UIImage(named: "watercolor-paper2", inBundle: bundle, compatibleWithTraitCollection: nil) else {
            return
        }
        paperTexture2 = image2.texture(device)
    }
    
}