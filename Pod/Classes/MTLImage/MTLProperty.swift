//
//  MTLProperty.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

public
enum MTLPropertyType: Int {
    case Value = 0,
    Point,
    Color,
    Selection,
    Image
}

public
class MTLProperty: NSObject, NSCoding {
    
    public var title: String!
    public var key: String!
    public var propertyType: MTLPropertyType!
    public var minimumValue: Float = 0.0
    public var defaultValue: Float = 0.5
    public var maximumValue: Float = 1.0
    public var selectionItems: [Int : String]?
    
    init(key: String, title: String) {
        super.init()
        self.key = key
        self.title = title
        self.propertyType = .Value
    }
    
    init(key: String, title: String, propertyType: MTLPropertyType) {
        super.init()
        self.key = key
        self.title = title
        self.propertyType = propertyType
    }
    
    
    
    //    MARK: - NSCoding
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title , forKey: "title")
        aCoder.encodeObject(key, forKey: "key")
        aCoder.encodeFloat(minimumValue, forKey: "minimumValue")
        aCoder.encodeFloat(maximumValue, forKey: "maximumValue")
        aCoder.encodeFloat(defaultValue, forKey: "defaultValue")
        aCoder.encodeObject(selectionItems, forKey: "selectionItems")
        aCoder.encodeInteger(propertyType.rawValue, forKey: "propertType")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        key = aDecoder.decodeObjectForKey("key") as! String
        title = aDecoder.decodeObjectForKey("title") as! String
        minimumValue = aDecoder.decodeFloatForKey("minimumValue")
        maximumValue = aDecoder.decodeFloatForKey("maximumValue")
        defaultValue = aDecoder.decodeFloatForKey("defaultValue")
        selectionItems = aDecoder.decodeObjectForKey("selectionItems") as? [Int: String]
        propertyType = MTLPropertyType(rawValue: aDecoder.decodeIntegerForKey("propertyType"))
    }
    
}
