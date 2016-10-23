//
//  MTLObject.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

public
class MTLObject: NSObject, MTLOutput {
    
    public var title: String = ""
    public var identifier: String = UUID().uuidString

    public var continuousUpdate: Bool {
        guard let input = input else {
            return false
        }
        return input.continuousUpdate
    }
    
    public func processIfNeeded() {
        
        if enabled && needsUpdate {
            update()
            process()
        }
        
    }
    
    
    // MARK: - Private Backers
    
    var enabled: Bool = true
    var internalTargets = [MTLOutput]()
    var internalNeedsUpdate = true
    
    public var texture: MTLTexture?
    
    var source: MTLInput? {
        get {
            var inp: MTLInput? = input
            while inp != nil {
                
                if let sourcePicture = inp as? MTLPicture {
                    return sourcePicture
                }
                
                #if !os(tvOS)
                    if let camera = inp as? MTLCamera {
                        return camera
                    }
                #endif
                
                if inp is MTLOutput {
                    inp = (inp as? MTLOutput)?.input
                }
            }
            return nil
        }
    }
    
    
    public func addTarget(_ target: MTLOutput) {
      
        var t = target
        internalTargets.append(t)
        t.input = self
        
//        if let picture = source as? MTLPicture {
//            picture.loadTexture()
//        }
    }
    
    public func removeTarget(_ target: MTLOutput) {
        var t = target
        
        t.input = nil
        
        var index: Int = NSNotFound
        if let filter = target as? MTLFilter {
            for i in 0 ..< internalTargets.count {
                if let f = internalTargets[i] as? MTLFilter {
                    if f == filter { index = i }
                }
            }
        }
        else if t is MTLView {
            for i in 0 ..< internalTargets.count {
                if internalTargets[i] is MTLView { index = i }
            }
        }
        
        if index != NSNotFound {
            internalTargets.remove(at: index)
        }
        texture = nil
    }
    
    public func removeAllTargets() {
        for var target in internalTargets {
            target.input = nil
        }
        internalTargets.removeAll()
    }
    
    public var input: MTLInput? {
        didSet {

            if let inputTexture = input?.texture {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat,
                                                                                 width: inputTexture.width,
                                                                                 height: inputTexture.height,
                                                                                 mipmapped: false)
                
                texture = context.device?.makeTexture(descriptor: textureDescriptor)
            }
            
            reload()
        }
    }

    
    public var commandBuffer: MTLCommandBuffer {
        if let buffer = input?.commandBuffer {
            return buffer
        }
        return context.commandQueue.makeCommandBuffer()
    }
    
    
    
    
    
    // MARK: - Subclassing
    
    func update() {
        
    }
    
    func process() {
        
    }
    
    func reload() {
        
    }
}

extension MTLObject: MTLInput {
    
    public var context: MTLContext {
        get {
            if let c = input?.context {
                return c
            }
            return MTLContext()
        }
    }
    
    public var device: MTLDevice   {
        return context.device
    }
    
    public var targets: [MTLOutput] {
        return internalTargets
    }
    
    /* Informs next object in the chain that a change has occurred and
     that changes need to be propogated through the chain. */
    
    public var needsUpdate: Bool {
        set {
            internalNeedsUpdate = newValue
            
            if newValue == true {
                
                for target in targets {
                    
                    if target is MTLObject {
                        (target as! MTLObject).needsUpdate = newValue
                    }
                    else if target is MTLView {
                        (target as! MTLView).setNeedsDisplay()
                    }
                }
            }
        }
        get {
            return internalNeedsUpdate
        }
    }
    
}


extension MTLObject {
    
    func clamp<T: Comparable>(_ value: inout T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
}
