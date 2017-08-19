//
//  MTLObject.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

@objc
public class MTLObject: NSObject, Output {
    
    public var title: String = ""
    public var identifier: String = UUID().uuidString

    public var needsUpdate: Bool = true {
        didSet {
            if needsUpdate == true {
                for target in targets {
                    if let object = target as? MTLObject {
                        object.needsUpdate = true
                    }
                    else if let view = target as? View {
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
    var internalTargets = [Output]()
    
    public var texture: MTLTexture?
    
    var source: Input? {
        get {
            var inp: Input? = input
            while inp != nil {
                
                if let sourcePicture = inp as? Picture {
                    return sourcePicture
                }
                
                #if !os(tvOS)
                    if let camera = inp as? Camera {
                        return camera
                    }
                #endif
                
                if inp is Output {
                    inp = (inp as? Output)?.input
                }
            }
            return nil
        }
    }
    
    
    public func addTarget(_ target: Output) {
      
        var t = target
        internalTargets.append(t)
        t.input = self
        
//        if let picture = source as? Picture {
//            picture.loadTexture()
//        }
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        
        t.input = nil
        
        var index: Int = NSNotFound
        if let filter = target as? Filter {
            for i in 0 ..< internalTargets.count {
                if let f = internalTargets[i] as? Filter {
                    if f == filter { index = i }
                }
            }
        }
        else if t is View {
            for i in 0 ..< internalTargets.count {
                if internalTargets[i] is View { index = i }
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
    
    public var input: Input? {
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
        if self.input == nil { return }
    }
    
    func process() {
        
    }
    
    func reload() {
        
    }
}

extension MTLObject: Input {
    
    public var context: Context {
        get {
            if let c = input?.context {
                return c
            }
            return Context()
        }
    }
    
    public var device: MTLDevice   {
        return context.device
    }
    
    public var targets: [Output] {
        return internalTargets
    }
        
}


extension MTLObject {
    
    func clamp<T: Comparable>(_ value: inout T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
}
