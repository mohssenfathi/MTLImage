//
//  MTLProperty.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/1/16.
//
//

import UIKit

public
class MTLProperty: NSObject {
    
    public var title: String!
    public var key: String!
    public var type: Any!
    public var minimumValue: Float = 0.0
    public var defaultValue: Float = 0.5
    public var maximumValue: Float = 1.0
    
    init(key: String, title: String, type: Any) {
        super.init()
        self.key = key
        self.title = title
        self.type = type
    }
    
    
}
