//
//  MTLContext.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import Metal

public
class MTLContext: NSObject {

    var device: MTLDevice!
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var processingSize: CGSize!
    var processingQueue: dispatch_queue_t!    
    var needsUpdate: Bool = true
    
    override init() {
        super.init()
        
        let destructor: dispatch_block_t = dispatch_block_create(DISPATCH_BLOCK_BARRIER) {
            
        }
        
        device = MTLCreateSystemDefaultDevice()
        if (device != nil && device.supportsFeatureSet(.iOS_GPUFamily1_v1)) {
            do {
                let bundle = NSBundle(forClass: MTLImage.classForCoder())
//                let path = bundle.pathForResource("default", ofType: "metallib")
//                let libData = NSData.dataWithContentsOfMappedFile(path!)
//                let data: dispatch_data_t = dispatch_data_create((libData?.bytes)!, (libData?.length)!, processingQueue, destructor)
//                try self.library = self.device.newLibraryWithData(data)
                
                let path = bundle.pathForResource("default", ofType: "metallib")
                try self.library = self.device.newLibraryWithFile(path!)
            } catch {
                print("Couldn't load precompiled metallib")
                self.library = self.device.newDefaultLibrary()
            }
            
            self.commandQueue = self.device.newCommandQueue()
            self.processingQueue = dispatch_queue_create("MTLImageProcessQueue", DISPATCH_QUEUE_SERIAL);
        } else {
            print("Device does not support metal")
        }
        
    }
    
}
