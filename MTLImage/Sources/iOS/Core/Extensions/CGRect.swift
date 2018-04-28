//
//  CGRect.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

import UIKit

extension CGRect {
    var mtlRegion: MTLRegion {
        return MTLRegion(
            origin: MTLOrigin(x: Int(origin.x), y: Int(origin.y), z: 0),
            size: MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
        )
    }
}
