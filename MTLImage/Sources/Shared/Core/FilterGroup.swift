//
//  FilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

public
class FilterGroup: MTLObject, NSCoding {

    override public init() {
        super.init()
        title = "Filter Group"
    }
    
    public var filters = [MTLObject]()
    
    public func add(_ filter: MTLObject) {
        
        if let last = filters.last {
            last.removeAllTargets()
            last.addTarget(filter)
        } else {
            let currentInput = input
            input?.removeAllTargets()
            input = currentInput
            input?.addTarget(filter)
        }
        
        for target in targets {
            filter.addTarget(target)
        }
        
        filters.append(filter)
    }
    
    public func insert(_ filter: MTLObject, index: Int) {
        
        guard filters.count > 0 else {
            add(filter)
            return
        }
        
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
        for target in targets {
            input?.addTarget(target)
        }
        
        filters.removeAll()
    }
    
    public func move(_ fromIndex: Int, toIndex: Int) {
        if fromIndex == toIndex { return }
        filters.swapAt(fromIndex, toIndex)
        rebuildFilterChain()
    }
    
    func rebuildFilterChain() {
        
        if filters.count == 0 {
            for var target in targets { target.input = input }
            return
        }
        
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
    public override func processIfNeeded() {
        filters.last?.processIfNeeded()
    }
    
    public override func process() {
        filters.last?.process()
    }
    
    public override var texture: MTLTexture? {
        get { return filters.last?.texture ?? input?.texture }
        set { super.texture = newValue }
    }
    
    public override func addTarget(_ target: Output) {
        targets.append(target)
        if let filter = filters.last {
            filter.removeAllTargets()
            for target in targets {
                filter.addTarget(target)
            }
        } else {
            if input?.targets.filter({ $0 == target }).count == 0 {
                input?.addTarget(target)
            }
//            input?.removeAllTargets()
//            for target in targets { input?.addTarget(target) }
        }
        needsUpdate = true
    }
    
    public override func removeTarget(_ target: Output) {
        // TODO: remove from targets
        filters.last?.removeTarget(target)
    }
    
    public override func removeAllTargets() {
        filters.last?.removeAllTargets()
        targets.removeAll()
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
            if let filter = filters.first {
                filter.input = input
                input?.addTarget(filter)
            }
            
//            rebuildFilterChain()
        }
    }
    
    public var category: String = ""
    public var filterDescription: String = ""
    
    
    //    MARK: - NSCoding
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title     , forKey: "title")
        aCoder.encode(id, forKey: "identifier")
        aCoder.encode(category, forKey: "category")
        aCoder.encode(filterDescription, forKey: "filterDescription")
        aCoder.encode(filters   , forKey: "filters")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        id         = aDecoder.decodeObject(forKey: "identifier") as! String
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
        filterGroup.id = id
        
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
