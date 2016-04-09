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
        
        self.device = MTLCreateSystemDefaultDevice()
        self.library = self.device.newDefaultLibrary()
        self.commandQueue = self.device.newCommandQueue()
        self.processingQueue = dispatch_queue_create("MTLImageProcessQueue", DISPATCH_QUEUE_SERIAL);
    }
    
}
