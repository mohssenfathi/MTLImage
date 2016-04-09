//
//  MTLFilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit
import MTLImage

public
class MTLFilterGroup: NSObject, MTLInput, MTLOutput {
    
    var filters = [MTLFilter]()
    var internalInput: MTLInput?
    var internalTargets = [MTLOutput]()
    
    public func add(filter: MTLFilter) {
        if let last = filters.last {
            last.addTarget(filter)
        } else {
            input?.addTarget(filter)
        }
        
        for target in internalTargets {
            filter.addTarget(target)
        }
        
        filters.append(filter)
    }
    
    public func insert(filter: MTLFilter, index: Int) {
        assert(index < filters.count)
        
        if index == 0 {
            filters.first?.input?.removeTarget(filters.first!)
            filters.first?.input?.addTarget(filter)
            filter > filters.first!
        }
        else {
            let previous = filters[index]
            
            for target in previous.targets {
                filter > target
            }
            
            previous.removeAllTargets()
            previous > filter
        }
        
        filters.insert(filter, atIndex: index)
    }
    
    public func removeAll() {
        filters.removeAll()
        internalInput?.removeAllTargets()
        for target in internalTargets {
            internalInput?.addTarget(target)
        }
    }
    
    
//    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            return filters.last?.texture
        }
    }
    
    public var context: MTLContext  {
        get {
            return (filters.first?.context)!
        }
    }
    
    public var device : MTLDevice   {
        get {
            return context.device
        }
    }
    
    public var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    public func addTarget(var target: MTLOutput) {
        internalTargets.append(target)
        filters.last?.addTarget(target)
    }
    
    public func removeTarget(var target: MTLOutput) {
        // TODO: remove from internal targets
        filters.last?.removeTarget(target)
    }
    
    public func removeAllTargets() {
        filters.last?.removeAllTargets()
    }
    
    
//    MARK: - MTLOutput
    
    public var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            internalInput = newValue
            if filters.count > 0 {
                input?.addTarget(filters.first!)
            }
        }
    }
}

public func += (filterGroup: MTLFilterGroup, filter: MTLFilter) {
    filterGroup.add(filter)
}

extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}
