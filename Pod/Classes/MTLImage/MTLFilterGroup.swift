//
//  MTLFilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

public
class MTLFilterGroup: MTLObject, NSCoding {
    
    override public init() {
        super.init()
        title = "Filter Group"
    }
    
    public var image: UIImage? {
        get {
            guard texture != nil else {
                return nil
            }
            return UIImage.imageWithTexture(texture!)
        }
    }
    
    public var filters = [MTLObject]()
    var internalInput: MTLInput?
    var internalTargets = [MTLOutput]()
    
    var internalTitle: String!
    public override var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = NSUUID().UUIDString
    public override var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    public func filterImage(image: UIImage) -> UIImage? {
        let picture = MTLPicture(image: image)
        picture > self
        let filteredImage = UIImage.imageWithTexture(texture!)
        
        picture.removeAllTargets()
                
        return filteredImage
    }
    
    func save() {
        MTLDataManager.sharedManager.save(self, completion: nil)
    }
    
    func updateFilterIndexes() {
//        for i in 0 ..< filters.count {
//            filters[i].index = i
//        }
    }
    
    public func add(filter: MTLObject) {
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
    
    public func insert(filter: MTLObject, index: Int) {
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
    
    public func remove(filter: MTLObject) {
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
    
    public override var texture: MTLTexture? {
        get {
            if filters.count > 0 {
                return filters.last?.texture
            }
            return input?.texture
        }
    }
    
    public override var context: MTLContext  {
        get {
            return (filters.first?.context)!
        }
    }
    
    public override var device : MTLDevice   {
        get {
            return context.device
        }
    }
    
    public override var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    public override func addTarget(target: MTLOutput) {
        internalTargets.append(target)
        if filters.count > 0 {
            filters.last!.addTarget(target)
        } else {
            input?.addTarget(target)
        }
        needsUpdate = true
    }
    
    public override func removeTarget(target: MTLOutput) {
        // TODO: remove from internal targets
        filters.last?.removeTarget(target)
    }
    
    public override func removeAllTargets() {
        filters.last?.removeAllTargets()
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
    
    public override var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            internalInput = newValue
            if filters.count > 0 {
                input?.addTarget(filters.first!)
            }
            needsUpdate = true
        }
    }
    
    
    //    MARK: - NSCoding
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title     , forKey: "title")
        aCoder.encodeObject(identifier, forKey: "identifier")
        aCoder.encodeObject(filters   , forKey: "filters")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        identifier = aDecoder.decodeObjectForKey("identifier") as! String
        title      = aDecoder.decodeObjectForKey("title") as! String
        filters    = aDecoder.decodeObjectForKey("filters") as! [MTLFilter]
        rebuildFilterChain()
    }
    

//    MARK: - Copying
    
    public override func copy() -> AnyObject {
        
        let filterGroup = MTLFilterGroup()
        
        filterGroup.title = title
        filterGroup.identifier = identifier
        
        for filter in filters {
            filterGroup.add(filter.copy() as! MTLObject)
        }
        
        return filterGroup
    }
}

public func += (filterGroup: MTLFilterGroup, filter: MTLObject) {
    filterGroup.add(filter)
}

public func > (left: MTLFilterGroup, right: MTLFilterGroup) {
    for target in left.targets {
        right.addTarget(target)
    }
    
    left.removeAllTargets()
    left.addTarget(right)
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
