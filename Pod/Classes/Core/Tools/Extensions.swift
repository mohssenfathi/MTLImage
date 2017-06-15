//
//  Extensions.swift
//  MTLImage-iOS10.0
//
//  Created by Mohssen Fathi on 6/9/17.
//

extension MTLTexture {
    
    func size() -> MTLSize {
        return MTLSize(width: width, height: height, depth: depth)
    }
    
}
