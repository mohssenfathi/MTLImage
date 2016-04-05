//
//  Tools.swift
//  Pods
//
//  Created by Mohssen Fathi on 3/30/16.
//
//

import UIKit

public
class Tools: NSObject {

    public class func normalize(value: Float, min: Float, max: Float) -> Float {
        return Tools.convert(value, oldMin: min, oldMax: max, newMin: 0, newMax: 1)
    }
    
    public class func convert(value: Float, oldMin: Float, oldMax: Float, newMin: Float, newMax: Float) -> Float {
        let normalizedValue = (value - oldMin)/(oldMax - oldMin);
        return newMin + (normalizedValue * (newMax - newMin))
    }
    
    public class func convert(value: Float, oldMin: Float, oldMid: Float, oldMax: Float, newMin: Float, newMid: Float, newMax: Float) -> Float {
        if (oldMin < oldMax && value < oldMid) {
            return Tools.convert(value, oldMin: oldMin, oldMax: oldMid, newMin: newMin, newMax: newMid)
        }
        else {
            return Tools.convert(value, oldMin: oldMid, oldMax: oldMax, newMin: newMid, newMax: newMax)
        }
    }
    
    private class func convert(value: Float, oldMin: Float, oldMax: Float, newMin: Float, newMid: Float, newMax: Float) -> Float {
        if (newMid == newMin || newMid == newMax) {
            return Tools.convert(value, oldMin: oldMin, oldMax: oldMax, newMin: newMin, newMax: newMax)
        }
        
        let normalizedValue = (value - oldMin)/(oldMax - oldMin);
        if normalizedValue < 0.5 {
            let adjustedMax = (newMid - newMin) + newMid;
            return Tools.convert(value, oldMin: 0, oldMax: 1, newMin: newMin, newMax: adjustedMax)
        }
        else {
            let adjustedMin = newMid - (newMax - newMid);
            return Tools.convert(value, oldMin: 0, oldMax: 1, newMin: adjustedMin, newMax: newMax)
        }
    }
    
    private class func convert(value: Float, oldMin: Float, oldMid: Float, oldMax: Float, newMin: Float, newMax: Float) -> Float {
        var newMid = (newMax - fabs(newMin))/2;
        if oldMid == oldMin { newMid = newMin }
        if oldMid == oldMax { newMid = newMax }
        return Tools.convert(value, oldMin: oldMin, oldMid: oldMid, oldMax: oldMax, newMin: newMin, newMid: newMid, newMax: newMax)
    }
    
    
    public class func imageFrame(imageSize: CGSize, rect: CGRect) -> CGRect {
        
        let phKoef = imageSize.height / rect.size.height
        let pwKoef = imageSize.width  / rect.size.width
        
        var newSize = CGSizeZero;
        var retRect = CGRectZero;
        
        if imageSize.width > imageSize.height {
            if imageSize.height / pwKoef > rect.size.height {
                newSize = CGSizeMake(imageSize.width / phKoef, rect.size.height)
                retRect = CGRectMake(rect.origin.x + (rect.size.width-newSize.width) / 2, rect.origin.y, newSize.width, newSize.height)
            }
            else{
                newSize = CGSizeMake(rect.size.width, imageSize.height / pwKoef)
                retRect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height-newSize.height) / 2, newSize.width, newSize.height)
            }
        }
        else {
            if imageSize.width / phKoef > rect.size.width {
                newSize = CGSizeMake(rect.size.width, imageSize.height / pwKoef)
                retRect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height-newSize.height) / 2, newSize.width, newSize.height)
            }
            else{
                newSize = CGSizeMake(imageSize.width / phKoef, rect.size.height)
                retRect = CGRectMake(rect.origin.x + (rect.size.width-newSize.width) / 2, rect.origin.y, newSize.width, newSize.height)
            }
        }
        
        return  retRect;
    }
    
}
