//
//  MTLImage-Additions.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation

public
extension MTLImage {
    
    public static var isMetalSupported: Bool {
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return false
        }
        
        var supported = false
        
        #if os(tvOS)
            supported = device.supportsFeatureSet(.tvOS_GPUFamily1_v1)
        #elseif os(macOS)
            supported = device.supportsFeatureSet(.macOS_GPUFamily1_v1)
        #elseif os(iOS)
            supported = device.supportsFeatureSet(.iOS_GPUFamily1_v1)
        #endif
        
        return supported
    }
}

public protocol Uniforms { }



//    MARK: - Operator Overloading

precedencegroup ChainPrecedence {
    associativity: left
}

infix operator --> : ChainPrecedence

@discardableResult
public func --> (left: Input , right: Output) -> Output {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: Input , right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

@discardableResult
public func --> (left: MTLObject, right: MTLObject) -> MTLObject {
    left.addTarget(right)
    return right
}

public func --> (left: MTLObject, right: Output) {
    left.addTarget(right)
}

public func + (left: Input, right: Output) {
    left.addTarget(right)
}

public func > (left: Input, right: Output) {
    left.addTarget(right)
}



func ==(left: MTLSize, right: MTLSize) -> Bool {
    return left.width == right.width && left.height == right.height && left.depth == right.depth
}
