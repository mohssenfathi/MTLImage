//
//  MTLInvertFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

public
class MTLInvertFilter: MTLFilter {
    
    public init() {
        super.init(functionName: "invert")
        title = "Invert"
        properties = []
    }
}
