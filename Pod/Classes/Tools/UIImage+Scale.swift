//
//  UIImage+Scale.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/22/16.
//
//

import UIKit

extension UIImage {
    
    // Something wrong with the scale
    
    func scaleToFill(size: CGSize) -> UIImage {
        
        let scaledImage: UIImage
        if size == CGSizeZero {
            scaledImage = self
        } else {
            let aspectRatio = self.size.width / self.size.height
            let scalingFactor = size.width / self.size.width > size.height / self.size.height ? size.width / self.size.width : size.height / self.size.height
            let newSize = CGSize(width: self.size.width * scalingFactor,
                                 height: self.size.height * scalingFactor)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let origin = CGPoint(x: (size.width - newSize.width) / 2, y: (size.height - newSize.height) / 2)
            let rect = CGRect(origin: origin, size: newSize)
            self.drawInRect(rect)
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        }
        return scaledImage
    }
    
    func scaleToFit(size: CGSize) -> UIImage {

        // Need to set clear color
        
        let ratio = self.size.width / self.size.height
        let sizeRatio = size.width / size.height
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
        
        if ratio > sizeRatio {
            x = 0.0
            width = size.width
            height = size.width / ratio
            y = (size.height - height)/2.0
        }
        else {
            y = 0.0
            height = size.height
            width = size.height * ratio
            x = (size.width - width)/2.0
        }
        
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        let rect = CGRectMake(x, y, width, height)
        CGContextFillRect(context, rect)
        self.drawInRect(rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func center(size: CGSize) -> UIImage {
        // Not working
        
        let x = (self.size.width  - size.width )/4.0
        let y = (self.size.height - size.height)/4.0
//
//        let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
//        let imageRef = CGImageCreateWithImageInRect(CGImage, rect);
//        return UIImage(CGImage: imageRef!)
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
        CGContextFillRect(context, rect)
        self.drawInRect(rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
}
