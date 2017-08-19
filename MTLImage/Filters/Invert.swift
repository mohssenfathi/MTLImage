//
//  Invert.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import UIKit

public
class Invert: Filter {
    
    public init() {
        super.init(functionName: "invert")
        title = "Invert"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
