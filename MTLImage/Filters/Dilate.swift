//
//  Dilate.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/17/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class Dilate: MPS {
    
    var dilateValues: UnsafePointer<Float>!
    
    var width: Float = 0.5 {
        didSet {
            clamp(&width, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    var height: Float = 0.5 {
        didSet {
            clamp(&height, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    var intensity: Float = 0.5 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func commonInit() {
        let intense = intensity * 5.0
//        let values1 = [[-2.0 * intense, -intense, 0.0         ],
//                      [-intense      , 1.0     , intense      ],
//                      [0.0           , intense , 2.0 * intense]]
        
        let values = [-2.0 * intense, -intense, 0.0, -intense, 1.0 , intense, 0.0, intense , 2.0 * intense]
        updateDilateValues(values)
        
        title = "Dilate"
        properties = [Property(key: "intensity", title: "Intensity"),
                      Property(key: "width", title: "Width"),
                      Property(key: "height", title: "Height")]
        
        update()
    }
    
    func updateDilateValues(_ values: UnsafePointer<Float>!) {
        dilateValues = values
    }
    
    override func update() {
        let w: Int = (Int(width  * 10) / 2) * 2 + 1
        let h: Int = (Int(height * 10) / 2) * 2 + 1
        
        kernel = MPSImageDilate(device: context.device, kernelWidth: w, kernelHeight: h, values: dilateValues)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
