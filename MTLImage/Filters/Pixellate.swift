//
//  Pixellate.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

struct PixellateUniforms: Uniforms {
    var dotRadius: Float = 0.5;
    var aspectRatio: Float = 0.6667
    var fractionalWidthOfPixel: Float = 0.02
}

public
class Pixellate: Filter {

    var uniforms = PixellateUniforms()
    var imageSize: CGSize?
    
    public var dotRadius: Float = 0.5 {
        didSet {
            clamp(&dotRadius, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "pixellate")
        title = "Pixellate"
        properties = [Property(key: "dotRadius", title: "Dot Radius")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
//        var add: Float = 0.2
//        if imageSize != nil {
//            add = Float(imageSize!.width) / 500.0
//        }
        
        uniforms.dotRadius = Tools.convert(dotRadius, oldMin: 0, oldMax: 1, newMin: 0.01, newMax: 3)
        updateUniforms(uniforms: uniforms)
    }
    
    override public var input: Input? {
        didSet {
            if originalImage != nil {
                imageSize = originalImage?.size
                uniforms.aspectRatio = 1.0 / Float(originalImage!.size.width / originalImage!.size.height)
            }
        }
    }
    
}
