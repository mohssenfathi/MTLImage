//
//  MetadataFormatter.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/3/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import ImageIO
import Photos

class MetadataFormatter: NSObject {

    static let sharedFormatter = MetadataFormatter()
    
    func formatMetadata(asset: PHAsset, completion: ((metadata: [AnyObject]) -> Void)?) {
        
//        let data = UIImageJPEGRepresentation(image, 1.0)
//        let source = CGImageSourceCreateWithData(data!, nil)
//        let metadata = source
//        NSDictionary *metadata = [[asset_ defaultRepresentation] metadata];
        
        let editingOptions = PHContentEditingInputRequestOptions()
        editingOptions.networkAccessAllowed = true
        
        asset.requestContentEditingInputWithOptions(editingOptions) { (contentEditingInput, info) in
            let ciImage = CIImage(contentsOfURL: (contentEditingInput?.fullSizeImageURL)!)
            let m = self.parseMetadata((ciImage?.properties)!)
            completion?(metadata: m)
        }
    }
    
    func parseMetadata(metadata: [String: AnyObject]) -> [AnyObject] {
        
        var array = [AnyObject]()
        if metadata["PixelHeight"] != nil {
            let resolution = String(format: "%ld x %ld px", metadata["PixelWidth"] as! Int, metadata["PixelHeight"] as! Int)
            array.append([
                "title" : "resolution",
                "value" : resolution
                ])
        }
        if let exif = metadata["{Exif}"] {
            parseExifMetadata(exif as! [String : AnyObject], formattedMetadata: array)
        }
        if let tiff = metadata["{TIFF}"] {
            parseTiffMetadata(tiff as! [String : AnyObject], formattedMetadata: array)
        }
        if let colorModel = metadata["ColorModel"] {
            array.append([
                "title" : "color",
                "value" : colorModel
            ])
        }
        if let orientation = metadata["Orientation"] as? Int {
            let value = title(UIImageOrientation(rawValue: orientation)!)
            array.append([
                "title" : "orientation",
                "value" : value
                ])
        }
        
        if let dpiWidth = metadata["DPIWidth"] {
            array.append([
                "title" : "DPI",
                "value" : String(dpiWidth)
                ])
        }
    
        return array;
    }
    
    func parseExifMetadata(exifMetadata: [String: AnyObject], formattedMetadata: [AnyObject]) {
        
        var fm = formattedMetadata
        
        if let date = exifMetadata["DateTimeOriginal"] {
            let s = formatDate(date as! String)
            fm.append([
                "title" : "date",
                "value" : s
                ])
        }
        
        if let flash = exifMetadata["Flash"] {
            let bin = toBinary(flash as! Int)
            let usedFlash = bin.characters.last == "1" ? "YES" : "NO"
            fm.append([
                "title" : "used flash",
                "value" : usedFlash
                ])
        }
        
        if let fNumber = exifMetadata["FNumber"] {
            let aperture = String(format: "f/%@", String(fNumber))
            fm.append([
                "title" : "aperture",
                "value" : aperture
                ])
        }
        
        if let duration = exifMetadata["ExposureTime"] as? Float {
            let value = formatShutterSpeed(duration)
            fm.append([
                "title" : "shutter speed",
                "value" : value
                ])
        }
        
        if let focalLength = exifMetadata["FocalLength"] as? Float {
            let value = String(format: "%ld", focalLength)
            fm.append([
                "title" : "focal length",
                "value" : value
                ])
        }
        
        
    }

    func parseTiffMetadata(tiffMetadata: [String: AnyObject], formattedMetadata: [AnyObject]) {
        var fm = formattedMetadata
        
        if let model = tiffMetadata["Model"] {
            fm.append([
                "title" : "shot with",
                "value" : model
                ])
        }
        
        if let software = tiffMetadata["Software"] {
            fm.append([
                "title" : "software",
                "value" : software
                ])
        }
    }


//    MARK: - Formatting

    func formatShutterSpeed(duration: Float) -> String {
        if duration > 1.0 { return String(format: "0.2f", duration) }
        let denominator = round(1.0/duration)
        return String(format: "1/%ld s", denominator)
    }

    func toBinary(input: Int) -> String {
        if input == 1 || input == 0 { return String(format: "%lu", input) }
        return String(format: "%@%lu", toBinary(input / 2), input % 2)
    }

    func formatDate(date: String) -> String {
        var components = date.componentsSeparatedByString(" ")
        var month = ""
        var day = ""
        var year = ""
        
        if components.count >= 2 {
            let dateString = components[0];
            let timeString = components[1];
            
            components = dateString.componentsSeparatedByString(":")
            if components.count >= 3 {
                year = components[0];
                month = components[1];
                day = components[2];
            }
            
            components = timeString.componentsSeparatedByString(":")
            if (components.count >= 3) {
                //                Handle later
            }
            
            switch (Int(month)!) {
            case 1:  month = "Jan.";  break;
            case 2:  month = "Feb.";  break;
            case 3:  month = "Mar.";  break;
            case 4:  month = "Apr.";  break;
            case 5:  month = "May";   break;
            case 6:  month = "Jun.";  break;
            case 7:  month = "Jul.";  break;
            case 8:  month = "Aug.";  break;
            case 9:  month = "Sept."; break;
            case 10: month = "Oct.";  break;
            case 11: month = "Nov.";  break;
            case 12: month = "Dec.";  break;
            default: break;
            }
        }
        
        return String(format: "%@ %@, %@", month, day, year)
    }

    func title(orientation: UIImageOrientation) -> String {
        switch orientation {
        case .Up:            return "Up";
        case .Right:         return "90˚ CW";
        case .Left:          return "90˚ CCW";
        case .Down:          return "Up";
        case .RightMirrored: return "90˚ CW, Flipped";
        case .LeftMirrored:  return "90˚ CCW, Flipped";
        default: return ""
        }
    }

}
