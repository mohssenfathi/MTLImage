//
//  MTLPicture.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import MetalKit

public
class MTLPicture: NSObject, MTLInput {

    private var internalTargets = [MTLOutput]()
    private var internalTexture: MTLTexture!
    var internalContext: MTLContext! = MTLContext()
    var pipeline: MTLComputePipelineState!
    var textureLoader: MTKTextureLoader!
    
    deinit {
        removeAllTargets()
        image = nil
        internalContext = nil
    }
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = UUID().uuidString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
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
            if let filter = target as? MTLFilter {
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
        
        self.title = "MTLPicture"
        self.image = image
        self.processingSize = image.size
        self.textureLoader = MTKTextureLoader(device: context.device)
        context.source = self
        
        loadTexture()
    }
    
    func loadTexture() {
        let flip = false
        self.internalTexture = image.texture(device, flip: flip, size: processingSize)
//        if let cgImage = image.cgImage {
//            do {
//                try self.internalTexture = textureLoader.newTexture(with: cgImage, options: nil)
//            }
//            catch {
//                print(error)
//            }
//        }
    }
    
    func chainLength() -> Int {
//        Count only first target for now
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
        return c
    }
    
    func length(_ target: MTLOutput) -> Int {
        var c = 1
        
        if let input = target as? MTLInput {
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

    public var context: MTLContext {
        get {
            return internalContext
        }
    }
    
    public var device: MTLDevice {
        get {
            return context.device
        }
    }
    
    public var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    public func addTarget(_ target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        loadTexture()
        t.input = self
    }
    
    public func removeTarget(_ target: MTLOutput) {
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
                    if let filter = target as? MTLFilter {
                        filter.needsUpdate = true
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
