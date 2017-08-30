//
//  Input.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/26/17.
//

import Metal

public protocol Input {
    
    var texture: MTLTexture? { get }
    var context: Context  { get }
    var device : MTLDevice   { get }
    var targets: [Output] { get }
    
    var title      : String { get set }
    var identifier : String { get set }
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
    
//    func removeDuplicates(in array: [Output]) -> [Output] {
//
//        var identifiers = Set(array.map({ $0.identifier }))
//
//        var new = [Output]()
//        for output in array {
//            if identifiers.contains(output.identifier) {
//                new.append(output)
//                identifiers.remove(output.identifier)
//            }
//        }
//
//        return new
//    }
}

