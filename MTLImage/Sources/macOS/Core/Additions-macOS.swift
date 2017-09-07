//
//  Additions-macOS.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation

public
extension Filter {
    
    /**
     Filters the provided input image
     
     - parameter image: The original image to be filtered
     - returns: An image filtered by the parent or the parents sub-filters
     */
    
    public func filter(_ image: NSImage) -> NSImage? {
        return nil
    }
    
    public var originalImage: NSImage? {
        return nil
    }
    
    public var image: NSImage? {
        return nil
    }
}



public
extension FilterGroup {
    
    public var image: NSImage? {
        return nil
    }
    
    public func filter(_ image: NSImage) -> NSImage? {
        return nil
    }
    
}
