//
//  Mosaic.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/6/16.
//
//

import CoreML
import Vision
import AVFoundation

@available(iOS 11.0, *)
public
class Mosaic: CoreMLFilter {
    
    var model = MLMosaic()
    var output: CVPixelBuffer?
    
    public override init() {
        super.init()
        title = "Mosaic"
    }

    override var processingSize: MTLSize? {
        return MTLSize(width: 720, height: 720, depth: 1)
    }
    
    public override func process() {

        resize.processIfNeeded()
        
        guard let pixelBuffer = processingTexture?.pixelBuffer else {
            print("Couldn't get pixel buffer")
            return
        }
        
        do {
            let out = try self.model.prediction(inputImage: pixelBuffer)
            self.output = out.outputImage
        } catch {
            print(error.localizedDescription)
        }

    }
    
    public override var texture: MTLTexture? {
        get {
            return output?.mtlTexture(device: device)
        }
        set {
            super.texture = newValue
        }
    }

}

