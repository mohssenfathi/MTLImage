//
//  MTLProperty.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

public
enum MTLPropertyType {
    case Value
    case Point
    case Color
    case Selection
    case Image
}

public
class MTLProperty: NSObject {
    
    public var title: String!
    public var key: String!
    public var type: Any!
    public var propertyType: MTLPropertyType!
    public var minimumValue: Float = 0.0
    public var defaultValue: Float = 0.5
    public var maximumValue: Float = 1.0
    public var selectionItems: [Int : String]?
    
    init(key: String, title: String) {
        super.init()
        self.key = key
        self.title = title
        self.type = Float()
        self.propertyType = .Value
    }
    
    init(key: String, title: String, type: Any, propertyType: MTLPropertyType) {
        super.init()
        self.key = key
        self.title = title
        self.type = type
        self.propertyType = propertyType
    }
    
    
}
