//
//  FilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

public
class FilterGroup: MTLObject, NSCoding {
    
    deinit {
        texture = nil
        input = nil
        context.source = nil
    }
    
    override public init() {
        super.init()
        title = "Filter Group"
    }
    
    public var image: UIImage? {
        
        if let filter = filters.last as? Filter {
            return filter.image
        }
        else if let filterGroup = filters.last as? FilterGroup {
            return filterGroup.image
        }
        
        return input?.texture?.image()
    }
    
    public var filters = [MTLObject]()
    
    public func filter(_ image: UIImage) -> UIImage? {
        
        let filter = self.copy() as! FilterGroup
        let picture = Picture(image: image.copy() as! UIImage)
        picture --> filter
        
        picture.needsUpdate = true
        filter.filters.last?.processIfNeeded()
        
        let filteredImage = filter.image
        
        picture.removeAllTargets()
        filter.removeAllTargets()
        
        filter.removeAll()
        
        picture.pipeline = nil
        filter.context.source = nil
        
        return filteredImage
    }
    
    func save() {
        DataManager.sharedManager.save(self, completion: nil)
    }
    
    func updateFilterIndexes() {
        //        for i in 0 ..< filters.count {
        //            filters[i].index = i
        //        }
    }
    
    public func add(_ filter: MTLObject) {
        
        if let last = filters.last {
            last.removeAllTargets()
            last.addTarget(filter)
        } else {
            let currentInput = input
            input?.removeAllTargets() // Might not want to do this
            input = currentInput
            input?.addTarget(filter)
        }
        
        for target in internalTargets {
            filter.addTarget(target)
        }
        
        filters.append(filter)
        updateFilterIndexes()
    }
    
    public func insert(_ filter: MTLObject, index: Int) {
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
        
        filters.insert(filter, at: index)
        updateFilterIndexes()
    }
    
    public func remove(_ filter: MTLObject) {
        let targets = filter.targets
        let input = filter.input
        
        filter.input?.removeTarget(filter)
        filter.removeAllTargets()
        
        for target in targets {
            input?.addTarget(target)
        }
        
        filters.removeObject(filter)
        needsUpdate = true
    }
    
    public func removeAll() {
        
        for filter in filters {
            filter.removeAllTargets()
        }
        
        input?.removeAllTargets()
        for target in internalTargets {
            input?.addTarget(target)
        }
        
        filters.removeAll()
    }
    
    public func move(_ fromIndex: Int, toIndex: Int) {
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
        
        filters.first?.needsUpdate = true
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
    
    //    public override var texture: MTLTexture? {
    //        get {
    //            if filters.count > 0 {
    //                return filters.last?.texture
    //            }
    //            return input?.texture
    //        }
    //    }
    
    public override func addTarget(_ target: Output) {
        internalTargets.append(target)
        if filters.count > 0 {
            filters.last!.addTarget(target)
        } else {
            input?.addTarget(target)
        }
        needsUpdate = true
    }
    
    public override func removeTarget(_ target: Output) {
        // TODO: remove from internal targets
        filters.last?.removeTarget(target)
    }
    
    public override func removeAllTargets() {
        filters.last?.removeAllTargets()
        internalTargets.removeAll()
    }
    
    public override var needsUpdate: Bool {
        set {
            for filter in filters {
                filter.needsUpdate = newValue
            }
        }
        get {
            if filters.last == nil { return false }
            return (filters.last?.needsUpdate)!
        }
    }
    
    //    MARK: - MTLOutput
    
    public override var input: Input? {
        didSet {
            rebuildFilterChain()
        }
    }
    
    //    public override var input: MTLInput? {
    //        get {
    //            return internalInput
    //        }
    //        set {
    //            internalInput = newValue
    //            if filters.count > 0 {
    //                input?.addTarget(filters.first!)
    //            }
    //            needsUpdate = true
    //        }
    //    }
    
    
    public var category: String = ""
    public var filterDescription: String = ""
    
    
    //    MARK: - NSCoding
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title     , forKey: "title")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(category, forKey: "category")
        aCoder.encode(filterDescription, forKey: "filterDescription")
        aCoder.encode(filters   , forKey: "filters")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        identifier = aDecoder.decodeObject(forKey: "identifier") as! String
        title      = aDecoder.decodeObject(forKey: "title") as! String
        filters    = aDecoder.decodeObject(forKey: "filters") as! [Filter]
        
        if let cat = aDecoder.decodeObject(forKey: "category") as? String {
            category = cat
        }
        
        if let fDesc = aDecoder.decodeObject(forKey: "filterDescription") as? String {
            filterDescription = fDesc
        }
        
        rebuildFilterChain()
    }
    
    
    //    MARK: - Copying
    public override func copy() -> Any {
        
        let filterGroup = FilterGroup()
        
        filterGroup.title = title
        filterGroup.identifier = identifier
        
        for filter in filters {
            filterGroup.add(filter.copy() as! MTLObject)
        }
        
        return filterGroup
    }
    
}

public func += (filterGroup: FilterGroup, filter: MTLObject) {
    filterGroup.add(filter)
}

public func -= (filterGroup: FilterGroup, filter: MTLObject) {
    filterGroup.remove(filter)
}

public func > (left: FilterGroup, right: FilterGroup) {
    for target in left.targets {
        right.addTarget(target)
    }
    
    left.removeAllTargets()
    left.addTarget(right)
}

extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

extension Array where Element: Equatable {
    
    public func unique() -> [Element] {
        var arrayCopy = self
        arrayCopy.uniqInPlace()
        return arrayCopy
    }
    
    mutating public func uniqInPlace() {
        var seen = [Element]()
        var index = 0
        for element in self {
            if seen.contains(element) {
                remove(at: index)
            } else {
                seen.append(element)
                index += 1
            }
        }
    }
}
