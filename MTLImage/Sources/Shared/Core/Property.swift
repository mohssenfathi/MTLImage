//
//  Property.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

public
class Property: NSObject, NSCoding {
    
    public
    enum PropertyType: Int {
        case value = 0,
        bool,
        point,
        rect,
        color,
        selection,
        image
    }
    
    public var title: String!
    public var key: String!
//    public var keyPath: AnyKeyPath!
    public var propertyType: PropertyType!
    public var minimumValue: Float = 0.0
    public var defaultValue: Float = 0.5
    public var maximumValue: Float = 1.0
    public var selectionItems: [Int : String]?
    
    init(key: String, title: String) {
        super.init()
        self.key = key
        self.title = title
        self.propertyType = .value
    }
    
    init(key: String, title: String, propertyType: PropertyType) {
        super.init()
        self.key = key
        self.title = title
        self.propertyType = propertyType
    }
    
    
    
    //    MARK: - NSCoding
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title , forKey: "title")
        aCoder.encode(key, forKey: "key")
        aCoder.encode(minimumValue, forKey: "minimumValue")
        aCoder.encode(maximumValue, forKey: "maximumValue")
        aCoder.encode(defaultValue, forKey: "defaultValue")
        aCoder.encode(selectionItems, forKey: "selectionItems")
        aCoder.encode(propertyType.rawValue, forKey: "propertType")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        key = aDecoder.decodeObject(forKey: "key") as? String
        title = aDecoder.decodeObject(forKey: "title") as? String
        minimumValue = aDecoder.decodeFloat(forKey: "minimumValue")
        maximumValue = aDecoder.decodeFloat(forKey: "maximumValue")
        defaultValue = aDecoder.decodeFloat(forKey: "defaultValue")
        selectionItems = aDecoder.decodeObject(forKey: "selectionItems") as? [Int: String]
        propertyType = PropertyType(rawValue: aDecoder.decodeInteger(forKey: "propertyType"))
    }
    
}
