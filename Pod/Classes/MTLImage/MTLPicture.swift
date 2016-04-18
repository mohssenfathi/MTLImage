//
//  MTLPicture.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

public
class MTLPicture: NSObject, MTLInput {

    private var internalTargets = [MTLOutput]()
    private var internalTexture: MTLTexture!
    var internalContext: MTLContext = MTLContext()
    var pipeline: MTLComputePipelineState!
    var dirty: Bool!
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = NSUUID().UUIDString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }

    public var image: UIImage! {
        didSet {
            loadTexture()
        }
    }
    
    public var processingSize: CGSize! {
        didSet {
            loadTexture()
            context.processingSize = processingSize
        }
    }
    
    public func setNeedsUpdate() {
        for target in targets {
            if let filter = target as? MTLFilter {
                filter.dirty = true
            }
        }
    }
    
    public func setProcessingSize(processingSize: CGSize, respectAspectRatio: Bool) {
        
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
        self.image = image
        self.processingSize = image.size
        self.title = "MTLPicture"
        loadTexture()
    }
    
    func loadTexture() {
        let flip = false
//        if chainLength() % 2 == 0 { flip = true }
        
//        var size = CGSize(width: CGImageGetWidth(image.CGImage), height: CGImageGetHeight(image.CGImage))
//        if processingSize != nil {
//            size = processingSize!
//        }
        
        self.internalTexture = image.texture(device, flip: flip, size: processingSize)
    }
    
    func chainLength() -> Int {
//        Count only first target for now
        if internalTargets.count == 0 { return 1 }
        let c = length(internalTargets.first!)
        return c
        
//        var count: Int = 1
//        var newCount: Int!
//        for target in internalTargets {
//            newCount = length(target, count: 0)
//            if newCount > count {
//                count = newCount
//            }
//        }
//        return count
    }
    
    func length(target: MTLOutput) -> Int {
        var c = 1
        
        if let input = target as? MTLInput {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }

        return c
        
//        var c = count
//        if let input = target as? MTLInput {
//            for t in input.targets {
//                c = c + length(target, count: c)
//            }
//        }
//        return c
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
    
    public func addTarget(target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        loadTexture()
        t.input = self
    }
    
    public func addTarget(target: MTLOutput, index: Int) {
//        var t = target
//        internalTargets.append(t)
//        t.input = self
//        if let picture = source as? MTLPicture {
//            picture.loadTexture()
//        }
    }
    
    public func removeTarget(target: MTLOutput) {
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
    
}
