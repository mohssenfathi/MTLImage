//
//  CoreMLFilter.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 12/17/17.
//

import UIKit
import CoreML

@available(iOS 11.0, *)
open
class CoreMLFilter: MTLObject {
    
    let resize = Resize()
    
    public override init() {
        super.init()
        resize.contentMode = .scaleAspectFill
    }
    
    var processingSize: MTLSize? {
        return input?.texture?.size()
    }
    
    var processingTexture: MTLTexture? {
        resize.processIfNeeded()
        return resize.texture
    }
    
    public override var input: Input? {
        didSet {
            resize.input = input
            resize.outputSize = processingSize
        }
    }
    
}

