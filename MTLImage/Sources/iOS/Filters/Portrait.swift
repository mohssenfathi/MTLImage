//
//  Portrait.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/18/18.
//

import UIKit
import AVFoundation

@available(iOS 11.0, *)
public class StageLight: DepthEffect {
    
    let colorGenerator = ColorGenerator()
    let darkenBlend = Blend(blendMode: .darken)
    
    public override init() {
        super.init()
        
        effect.add(colorGenerator)
//        darkenBlend.inputProvider = { [weak self] in
//            return $0 == 0 ? self?.colorGenerator : nil
//        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 11.0, *)
public class Portrait: DepthEffect {
    
    let blur = GaussianBlur()
    var intensity: Float = 0.1 {
        didSet { blur.sigma = intensity }
    }
    
    public override init() {
        super.init()

        blur.sigma = intensity
        effect.add(blur)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 11.0, *)
public class PortraitDesaturate: DepthEffect {
    
    let sat = Saturation(saturation: 0.0)
    
    public override init() {
        super.init()
        effect.add(sat)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



@available(iOS 11.0, *)
public class DepthEffect: FilterGroup {
    
    public var showRawDepth: Bool = false {
        didSet { blend.showMask = showRawDepth }
    }
    
    public var focus: Float = 0.5 {
        didSet { depthProcessor.focus = focus }
    }

    var effect = FilterGroup()
    let depthProcessor = DepthProcessor()
    var secondaryInput: TextureInput!
    public var blend = MaskBlend()
    
    public convenience init(effect: FilterGroup) {
        self.init()
        self.effect = effect
    }
    
    public override init() {
        super.init()
        
        add(effect)
        add(blend)
        
        secondaryInput = TextureInput { [weak self] in
            return self?.input?.texture
        }
        
        blend.maskInput = depthProcessor
        blend.secondaryInput = secondaryInput
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override var input: Input? {
        didSet {
            input?.addTarget(depthProcessor)
        }
    }
    
    public override func reset() {
        super.reset()
        depthProcessor.reset()
    }
}
