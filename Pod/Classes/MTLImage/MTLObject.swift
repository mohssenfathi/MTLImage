//
//  MTLObject.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

public
class MTLObject: NSObject, MTLInput, MTLOutput {

//    MARK: - MTLInput
    public var texture: MTLTexture? { get { return nil } }
    public var context: MTLContext  { get { return MTLContext() }}
    public var device : MTLDevice   { get { return context.device }}
    public var targets: [MTLOutput] { get { return [] }}
    
    public var title: String {
        get {  return "" }
        set {}
    }
    
    public var identifier: String! {
        get { return "" }
        set {}
    }
    public var needsUpdate: Bool {
        get { return false }
        set {}
    }
        
    public func addTarget(target: MTLOutput) {}
    public func removeTarget(target: MTLOutput) {}
    public func removeAllTargets() {}

//    MARK: - MTLOutput
    public var input: MTLInput? {
        get { return nil }
        set {}
    }
    
    
    
    //    MARK: - Tools
    
    func clamp<T: Comparable>(inout value: T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
}
