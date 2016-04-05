//
//  MTLTypes.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/2/16.
//
//

import Foundation

typealias MTLFloat = Float32

public struct MTLFloat3 {
    var one  : MTLFloat
    var two  : MTLFloat
    var three: MTLFloat
}

public struct MTLFloat4 {
    var one  : MTLFloat
    var two  : MTLFloat
    var three: MTLFloat
    var four : MTLFloat
};

public struct MTLFloat3x3 {
    var one  : MTLFloat3
    var two  : MTLFloat3
    var three: MTLFloat3
}

public struct MTLFloat4x4 {
    var one  : MTLFloat4
    var two  : MTLFloat4
    var three: MTLFloat4
    var four : MTLFloat4
}
