//
//  Emboss.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

public
class Emboss: Convolution {

    public var intensity: Float = 0.0 {
        didSet {
            clamp(&intensity, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    override init() {
        super.init()
        title = "Emboss"
        properties = [Property(key: "intensity", title: "Intensity")]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        let intense = intensity * 1.25
        convolutionMatrix = [[-2.0 * intense, -intense, 0.0          ],
                             [-intense      , 1.0     , intense      ],
                             [0.0           , intense , 2.0 * intense]];
    }
    
}
