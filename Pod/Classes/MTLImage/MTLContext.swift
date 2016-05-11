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
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var processingSize: CGSize!
    var processingQueue: dispatch_queue_t!    
    var needsUpdate: Bool = true
    let semaphore = dispatch_semaphore_create(3)
    
    override init() {
        super.init()
        
        device = MTLCreateSystemDefaultDevice()
        if (device != nil) {
        
            if useMetalib {
                do {
                    let bundle = NSBundle(forClass: MTLImage.classForCoder())
                    let path = bundle.pathForResource("default", ofType: "metallib")
                    try self.library = self.device.newLibraryWithFile(path!)
                } catch {
                    print("Couldn't load precompiled metallib")
                    self.library = self.device.newDefaultLibrary()
                }
            }
            else {
                #if os(tvOS)
                    if !device.supportsFeatureSet(.TVOS_GPUFamily1_v1) { return }
                #endif
                
                #if os(iOS)
                    if !device.supportsFeatureSet(.iOS_GPUFamily1_v1) { return }
                #endif
                
                self.library = self.device.newDefaultLibrary()
            }
            
            self.commandQueue = self.device.newCommandQueue()
            self.processingQueue = dispatch_queue_create("MTLImageProcessQueue", DISPATCH_QUEUE_SERIAL);
        } else {
            print("Device does not support metal")
        }
        
    }
    
}
