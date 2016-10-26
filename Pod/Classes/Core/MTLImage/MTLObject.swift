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

    public var needsUpdate: Bool = true {
        didSet {
            if needsUpdate == true {
                for target in targets {
                    if let object = target as? MTLObject {
                        object.needsUpdate = true
                    }
                    else if let view = target as? MTLView {
                        view.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
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
    
    
    var enabled: Bool = true
    var internalTargets = [MTLOutput]()
    
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
        
}


extension MTLObject {
    
    func clamp<T: Comparable>(_ value: inout T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
}
