//
//  MTLImage-AR.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/17/18.
//

import ARKit

@available(iOS 11.0, *)
public protocol AROutput {
    var arFrame: ARFrame? { get set }
}
