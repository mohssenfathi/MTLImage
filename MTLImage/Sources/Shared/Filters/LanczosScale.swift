//
//  LanczosScale.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import MetalPerformanceShaders

public
class LanczosScale: MPS {
    
    var scaleTransform: MPSScaleTransform = MPSScaleTransform(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    var transformPointer: UnsafePointer<MPSScaleTransform>!
    
    @objc public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            scaleTransform = MPSScaleTransform(scaleX: Double(scale), scaleY: Double(scale), translateX: 0, translateY: 0)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func commonInit() {
        
        title = "Lanczos Scale"
        properties = [Property(key: "scale", title: "Scale")] //,
//                      Property(key: "width", title: "Width"),
//                      Property(key: "height", title: "Height")]
        
        transformPointer = withUnsafePointer(to: &scaleTransform, { (pointer: UnsafePointer<MPSScaleTransform>) -> UnsafePointer<MPSScaleTransform>? in
            return pointer
        })
        
        kernel = MPSImageLanczosScale(device: context.device)
        
        update()
    }
    
    override public func update() {
        (kernel as! MPSImageLanczosScale).scaleTransform = transformPointer
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
