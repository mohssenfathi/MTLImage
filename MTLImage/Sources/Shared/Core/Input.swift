//
//  Input.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/26/17.
//

import Metal

public protocol Input {
    
    var texture: MTLTexture? { get set }
    var targets: [Output]    { get set }
    var context: Context     { get }
    var device : MTLDevice   { get }
    
    var title      : String { get set }
    var id         : String { get set }
    var needsUpdate: Bool   { get set }
    var continuousUpdate: Bool { get }
    
    func addTarget(_ target: Output)
    func removeTarget(_ target: Output)
    func removeAllTargets()
    func processIfNeeded()
}

public extension Input {
    
    public func processIfNeeded() { }
    public mutating func setNeedsUpdate() {
        needsUpdate = true
    }
    
    var destinations: [Output] {
        var dests = [Output]()
        
        if targets.count == 0, let out = self as? Output {
            dests.append(out)
        }
        
        for target in targets {
            if let obj = target as? MTLObject {
                dests.append(contentsOf: obj.destinations)
            } else {
                dests.append(target)
            }
        }
        
        return dests
    }

    public mutating func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
    }
    
    public mutating func removeAllTargets() {
        targets.removeAll()
    }
}

