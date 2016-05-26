//
//  MTLContext.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

// Set to true to use compiled shaders
let useMetalib = false

public
class MTLContext: NSObject {

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var processingSize: CGSize!
    var processingQueue: dispatch_queue_t!    
    var needsUpdate: Bool = true
    let semaphore = dispatch_semaphore_create(3)
    
    private var internalLibrary: MTLLibrary!
    var library: MTLLibrary! {
        get {
            if internalLibrary == nil {
                loadLibrary()
            }
            return internalLibrary
        }
    }
    
    override init() {
        super.init()
        
        device = MTLCreateSystemDefaultDevice()
        if (device != nil) {
            
            #if os(tvOS)
                if !device.supportsFeatureSet(.TVOS_GPUFamily1_v1) { return }
            #endif
            
            #if os(iOS)
                if !device.supportsFeatureSet(.iOS_GPUFamily1_v1) { return }
            #endif
        
            loadLibrary()
            self.commandQueue = self.device.newCommandQueue()
            self.processingQueue = dispatch_queue_create("MTLImageProcessQueue", DISPATCH_QUEUE_SERIAL);
        } else {
            print("Device does not support metal")
        }
        
    }
    
    func loadLibrary() {
        if useMetalib {
            do {
                let bundle = NSBundle(forClass: MTLImage.classForCoder())
                let path = bundle.pathForResource("default", ofType: "metallib")
                try internalLibrary = self.device.newLibraryWithFile(path!)
            } catch {
                print(error)
                //                    self.library = self.device.newDefaultLibrary()
            }
        }
        else {
            internalLibrary = self.device.newDefaultLibrary()
        }

    }
    
}
