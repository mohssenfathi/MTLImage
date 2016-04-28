//
//  MTLFilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

public
class MTLFilterGroup: NSObject, MTLInput, MTLOutput {
    
    public var filters = [MTLFilter]()
    var internalInput: MTLInput?
    var internalTargets = [MTLOutput]()
    
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
    
    override public init() {
        super.init()
        title = "Filter Group"
    }
    
    func save() {
        MTLDataManager.sharedManager.save(self, completion: nil)
    }
    
    func updateFilterIndexes() {
        for i in 0 ..< filters.count {
            filters[i].index = i
        }
    }
    
    public func add(filter: MTLFilter) {
        if let last = filters.last {
            last.removeAllTargets()
            last.addTarget(filter)
        } else {
            input?.removeAllTargets() // Might not want to do this
            input?.addTarget(filter)
        }
        
        for target in internalTargets {
            filter.addTarget(target)
        }
        
        filters.append(filter)
        updateFilterIndexes()
    }
    
    public func insert(filter: MTLFilter, index: Int) {
        assert(index < filters.count)
        
        if index == 0 {
            filter > filters.first!
            filters.first?.input?.addTarget(filter)
            filters.first?.input?.removeTarget(filters.first!)
        }
        else {
            let previous = filters[index - 1]
            
            for target in previous.targets {
                filter.addTarget(target)
            }
            
            previous.removeAllTargets()
            previous.addTarget(filter)
        }
        
        filters.insert(filter, atIndex: index)
        updateFilterIndexes()
    }
    
    public func remove(filter: MTLFilter) {
        let targets = filter.targets
        let input = filter.input

        filter.input?.removeTarget(filter)
        filter.removeAllTargets()
        
        for target in targets {
            input!.addTarget(target)
        }

        filters.removeObject(filter)
        needsUpdate = true
    }
    
    public func removeAll() {
        
        for filter in filters {
            filter.removeAllTargets()
        }
        
        internalInput?.removeAllTargets()
        for target in internalTargets {
            internalInput?.addTarget(target)
        }
        
        filters.removeAll()
    }
    
    public func move(fromIndex: Int, toIndex: Int) {
        if fromIndex == toIndex { return }

        swap(&filters[fromIndex], &filters[toIndex])
        rebuildFilterChain()
        
//        let filter = filters[fromIndex]
//        remove(filter)
//        
//        var index = toIndex
//        index -= (toIndex > fromIndex) ? 1 : 0
//        
//        insert(filter, index: index)
//        
//        filters.last?.removeAllTargets()
//        for target in targets {
//            filters.last?.addTarget(target)
//        }
    }
    
    func rebuildFilterChain() {
        if filters.count == 0 { return }
        
        input?.removeAllTargets()
        for filter in filters {
            filter.removeAllTargets()
        }
        
        input?.addTarget(filters.first!)
        for i in 1 ..< filters.count {
            filters[i - 1].addTarget(filters[i])
        }
        
        for target in targets {
            filters.last?.addTarget(target)
        }
        
        filters.first?.dirty = true
    }
    
    func printFilters() {
        var chain: String = ""
        
        chain += ((input?.title)! + " --> ")
        
        for filter in filters {
            if filter.targets.count > 1 {
                chain += "["
                for target in filter.targets {
                    chain += (target.title + ", ")
                }
                chain += "] --> "
            } else {
                chain += (targets.first!.title + " --> ")
            }
        }
        
        if targets.count > 1 {
            chain += "["
            for target in targets {
                chain += (target.title + ", ")
            }
            chain += "]"
        }
        else {
            chain += (targets.first!.title + " --> ")
        }
        
        print(chain)
    }
    
//    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            if filters.count > 0 {
                return filters.last?.texture
            }
            return input?.texture
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
    
    public func addTarget(target: MTLOutput) {
        internalTargets.append(target)
        if filters.count > 0 {
            filters.last!.addTarget(target)
        } else {
            input?.addTarget(target)
        }
    }
    
    public func removeTarget(target: MTLOutput) {
        // TODO: remove from internal targets
        filters.last?.removeTarget(target)
    }
    
    public func removeAllTargets() {
        filters.last?.removeAllTargets()
    }

    public var needsUpdate: Bool {
        set {
            filters.first?.needsUpdate = newValue
        }
        get {
            return (filters.last?.needsUpdate)!
        }
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
