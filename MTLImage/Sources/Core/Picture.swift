//
//  Picture.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import MetalKit

public
class Picture: NSObject, Input {
    
    public var identifier: String = UUID().uuidString
    public var title: String = "Picture"

    public var continuousUpdate: Bool {
        return false
    }

    private var internalTargets = [Output]()
    private var internalTexture: MTLTexture!
    var internalContext: Context! = Context()
    var pipeline: MTLComputePipelineState!
    var textureLoader: MTKTextureLoader!
    
    deinit {
        removeAllTargets()
        image = nil
        internalContext = nil
    }
    
    public var image: UIImage! {
        didSet {
            if processingSize == CGSize.zero {
                processingSize = image.size
            }
            loadTexture()
            needsUpdate = true
        }
    }
    
    public func setNeedsUpdate() {
        for target in targets {
            if let filter = target as? Filter {
                filter.needsUpdate = true
            }
        }
    }
    
    public var processingSize: CGSize! {
        didSet {
            loadTexture()
            context.processingSize = processingSize
        }
    }
    
    public func setProcessingSize(_ processingSize: CGSize, respectAspectRatio: Bool) {
        
        var size = processingSize
        if respectAspectRatio == true {
            if size.width > size.height {
                size.height = size.width / (image.size.width / image.size.height)
            }
            else {
                size.width = size.height * (image.size.width / image.size.height)
            }
        }
        
        self.processingSize = size
    }
    
    public init(image: UIImage) {
        super.init()
        
        self.title = "Picture"
        self.image = image
        self.processingSize = image.size
        self.textureLoader = MTKTextureLoader(device: context.device)
        context.source = self
        
        loadTexture()
    }
    
    func loadTexture() {

        self.internalTexture = image.texture(device, flip: false, size: processingSize)
//        if let texture = image.texture(device, flip: false, size: processingSize) {
//            self.internalTexture = texture.makeTextureView(pixelFormat: texture.pixelFormat)
//        }
        
    }
    
    func chainLength() -> Int {
//        Count only first target for now
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
        return c
    }
    
    func length(_ target: Output) -> Int {
        var c = 1
        
        if let input = target as? Input {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }

        return c
    }
    
//    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            return self.internalTexture
        }
    }

    public var context: Context {
        get {
            return internalContext
        }
    }
    
    public var device: MTLDevice {
        get {
            return context.device
        }
    }
    
    public var commandBuffer: MTLCommandBuffer? {
        return context.commandQueue.makeCommandBuffer()
    }
    
    public var targets: [Output] {
        get {
            return internalTargets
        }
    }
    
    public func addTarget(_ target: Output) {
        var t = target
        internalTargets.append(t)
        loadTexture()
        t.input = self
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
//      TODO:   remove from internalTargets
    }
    
    public func removeAllTargets() {
//        for var target in internalTargets {
//            target.input = nil
//        }
        internalTargets.removeAll()
    }
    
    
    private var privateNeedsUpdate = true
    public var needsUpdate: Bool {
        set {
            privateNeedsUpdate = newValue
            if newValue == true {
                for target in targets {
                    if let filter = target as? Filter {
                        filter.needsUpdate = true
                    }
                    else if let view = target as? View {
                        view.setNeedsDisplay()
                    }
                }
            }
        }
        get {
            return privateNeedsUpdate
        }
    }
    
    
    public func didFinishProcessing() {
        context.semaphore.signal()
    }
}
