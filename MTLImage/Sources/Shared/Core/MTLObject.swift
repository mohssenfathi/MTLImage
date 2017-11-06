//
//  MTLObject.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import Foundation

@objc
open class MTLObject: NSObject, Output {
    
    public var isEnabled: Bool = true
    public var title: String = ""
    public var id: String = UUID().uuidString
    public var properties: [Property] = []
    
    public var needsUpdate: Bool = true {
        didSet {
            if needsUpdate == true {
                for target in targets {
                    if var object = target as? MTLObject {
                        object.setNeedsUpdate()
                    }
                    else if let view = target as? View {
                        #if os(macOS)
//                            view.setNeedsDisplay()
                        #else
                            view.setNeedsDisplay()
                        #endif
                        
                    }
                }
            }
        }
    }
        
    public var continuousUpdate: Bool {
        return input?.continuousUpdate ?? false
    }
    
    public func processIfNeeded() {
        
        if !isEnabled {
            input?.processIfNeeded()
            texture = input?.texture
            return
        }
        
        if needsUpdate {
            update()
            process()
        }
        
    }
    
    public var texture: MTLTexture?
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        
        t.input = nil
        
        var index: Int = NSNotFound
        if let filter = target as? Filter {
            for i in 0 ..< targets.count {
                if let f = targets[i] as? Filter {
                    if f == filter { index = i }
                }
            }
        }
        else if t is View {
            for i in 0 ..< targets.count {
                if targets[i] is View { index = i }
            }
        }
        
        if index != NSNotFound {
            targets.remove(at: index)
        }
        
        texture = nil
    }
    
    public func removeAllTargets() {
        for var target in targets {
            target.input = nil
        }
        targets.removeAll()
    }
    
    public var input: Input? {
        didSet {
            initTexture()
            reload()
        }
    }

    public var targets: [Output] = []
    
    func initTexture() {
        if let inputTexture = input?.texture {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat,
                                                                             width: inputTexture.width,
                                                                             height: inputTexture.height,
                                                                             mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            texture = context.device?.makeTexture(descriptor: textureDescriptor)
        }
    }
    
    // MARK: - Subclassing
    
    open func update() {
        if self.input == nil { return }
    }
    
    open func process() {
        
    }
    
    open func reload() {
        
    }
    
}

extension MTLObject: Input {
    
    public var context: Context {
        get {
            if let c = input?.context { return c }
            return Context()
        }
    }
    
    public var device: MTLDevice {
        return context.device
    }
    
}


extension MTLObject {
    
    func clamp<T: Comparable>(_ value: inout T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
}
