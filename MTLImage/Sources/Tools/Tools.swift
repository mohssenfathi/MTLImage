//
//  Tools.swift
//  Pods
//
//  Created by Mohssen Fathi on 3/30/16.
//
//

import UIKit

public
protocol Numeric {
    static func -(left: Self, right: Self) -> Self
    static func +(left: Self, right: Self) -> Self
    static func *(left: Self, right: Self) -> Self
    static func /(left: Self, right: Self) -> Self
//    static func %(left: Self, right: Self) -> Self
    static prefix func -(value: Self) -> Self
    init(_ f: Float)
    init(_ i: Int)
}

extension Double : Numeric {}
extension Float  : Numeric {}
extension Int    : Numeric {}
extension Int8   : Numeric {}
extension Int16  : Numeric {}
extension Int32  : Numeric {}
extension Int64  : Numeric {}
extension CGFloat: Numeric {}

public
class Tools: NSObject {

    public class func normalize<T>(_ value: T, min: T, max: T) -> T where T: Numeric, T: Comparable {
        return Tools.convert(value, oldMin: min, oldMax: max, newMin: T(0), newMax: T(1))
    }
    
    public class func convert<T>(_ value: T, oldMin: T, oldMax: T, newMin: T, newMax: T) -> T where T: Numeric, T: Comparable {
        let normalizedValue = (value - oldMin)/(oldMax - oldMin);
        return newMin + (normalizedValue * (newMax - newMin))
    }
    
    public class func convert<T>(_ value: T, oldMin: T, oldMid: T, oldMax: T, newMin: T, newMid: T, newMax: T) -> T where T:Numeric, T:Comparable {
        if (oldMin < oldMax && value < oldMid) {
            return Tools.convert(value, oldMin: oldMin, oldMax: oldMid, newMin: newMin, newMax: newMid)
        }
        else {
            return Tools.convert(value, oldMin: oldMid, oldMax: oldMax, newMin: newMid, newMax: newMax)
        }
    }
    
    private class func convert<T>(_ value: T, oldMin: T, oldMax: T, newMin: T, newMid: T, newMax: T) -> T where T:Numeric, T: Comparable {
        if (newMid == newMin || newMid == newMax) {
            return Tools.convert(value, oldMin: oldMin, oldMax: oldMax, newMin: newMin, newMax: newMax)
        }
        
        let normalizedValue = (value - oldMin)/(oldMax - oldMin);
        if normalizedValue < T(0.5) {
            let adjustedMax = (newMid - newMin) + newMid;
            return Tools.convert(value, oldMin: T(0), oldMax: T(1), newMin: newMin, newMax: adjustedMax)
        }
        else {
            let adjustedMin = newMid - (newMax - newMid);
            return Tools.convert(value, oldMin: T(0), oldMax: T(1), newMin: adjustedMin, newMax: newMax)
        }
    }
    
//    private class func convert<T where T: Numeric, T: Equatable, T: Comparable>(value: T, oldMin: T, oldMid: T, oldMax: T, newMin: T, newMax: T) -> T {
//        var newMid = (newMax - tabs(newMin))/2;
//        if oldMid == oldMin { newMid = newMin }
//        if oldMid == oldMax { newMid = newMax }
//        return Tools.convert(value, oldMin: oldMin, oldMid: oldMid, oldMax: oldMax, newMin: newMin, newMid: newMid, newMax: newMax)
//    }
    
    private class func tabs<T>(_ x: T) -> T where T: Numeric, T: Comparable {
        if x < T(0) { return -x }
        else        { return  x }
    }
    
    public class func imageFrame(_ imageSize: CGSize, rect: CGRect) -> CGRect {
        
        let phKoef = imageSize.height / rect.size.height
        let pwKoef = imageSize.width  / rect.size.width
        
        var newSize = CGSize.zero;
        var retRect = CGRect.zero;
        
        if imageSize.width > imageSize.height {
            if imageSize.height / pwKoef > rect.size.height {
                newSize = CGSize(width: imageSize.width / phKoef, height: rect.size.height)
                retRect = CGRect(x: rect.origin.x + (rect.size.width-newSize.width) / 2, y: rect.origin.y, width: newSize.width, height: newSize.height)
            }
            else{
                newSize = CGSize(width: rect.size.width, height: imageSize.height / pwKoef)
                retRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.size.height-newSize.height) / 2, width: newSize.width, height: newSize.height)
            }
        }
        else {
            if imageSize.width / phKoef > rect.size.width {
                newSize = CGSize(width: rect.size.width, height: imageSize.height / pwKoef)
                retRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.size.height-newSize.height) / 2, width: newSize.width, height: newSize.height)
            }
            else{
                newSize = CGSize(width: imageSize.width / phKoef, height: rect.size.height)
                retRect = CGRect(x: rect.origin.x + (rect.size.width-newSize.width) / 2, y: rect.origin.y, width: newSize.width, height: newSize.height)
            }
        }
        
        return  retRect;
    }
    
    public class func clamp<T: Comparable>(_ value: inout T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
    public class func odd(_ value: inout Int) {
        Tools.even(&value)
        value += 1
    }
    
    public class func even(_ value: inout Int) {
        value = value / 2 * 2
    }
    
    public class func odd(_ value: Int) -> Int {
        return Tools.even(value) + 1
    }
    
    public class func even(_ value: Int) -> Int {
        return value / 2 * 2
    }
    
    public class func gcd(_ a: Int, b: Int) -> Int {
        if b == 0 {
            return a
        } else {
            if a > b {
                return gcd(a - b, b: b)
            } else {
                return gcd(a, b: b-a)
            }
        }
    }
    
    
    /**
     Finds the largest integer that will evenly divide a
     
     - parameter a: The integer to be divided
     - returns: The largest integer that evenly divides a
     */
    
    public class func greatestDivisor(_ a: Int) -> Int {
        var i = 2
        while (a % i != 0) { i += 1 }
        return a / i
    }
    
    /**
     Finds the largest integer that will evenly divide a and is less than `below`
     
     - parameter a: The integer to be divided
     - parameter below: The maximum value of the divisor returned
     - returns: The largest integer that evenly divides a and is less than `below`
     */
    public class func greatestDivisor(_ a: Int, below: Int) -> Int {
        // Could use improvement
        var i = below
        while (a % i != 0 && i > 1) { i -= 1 }
        if i <= 1 { return NSNotFound }
        return i
    }
    
    public class func contents<T>(count: Int, data: UnsafePointer<T>) -> [T] {
        let buffer = UnsafeBufferPointer(start: data, count: count);
        return Array(buffer)
    }
    
//    func contents<T>(length: Int, data: UnsafePointer<UInt8>, _: T.Type) -> [T] {
//        let buffer = UnsafeBufferPointer<T>(start: UnsafePointer(data), count: length/MemoryLayout<T>.stride);
//        return Array(buffer)
//    }
}
