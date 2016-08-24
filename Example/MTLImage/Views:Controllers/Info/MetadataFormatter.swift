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
    
    func formatMetadata(_ asset: PHAsset, completion: ((_ metadata: [[String:Any]]) -> Void)?) {
        
//        let data = UIImageJPEGRepresentation(image, 1.0)
//        let source = CGImageSourceCreateWithData(data!, nil)
//        let metadata = source
//        NSDictionary *metadata = [[asset_ defaultRepresentation] metadata];
        
        let editingOptions = PHContentEditingInputRequestOptions()
        editingOptions.isNetworkAccessAllowed = true
        
        asset.requestContentEditingInput(with: editingOptions) { (contentEditingInput, info) in
            let ciImage = CIImage(contentsOf: (contentEditingInput?.fullSizeImageURL)!)
            let m = self.parseMetadata((ciImage?.properties)! as [String : AnyObject])
            completion?(m)
        }
    }
    
    func parseMetadata(_ metadata: [String: AnyObject]) -> [[String:Any]] {
        
        var array = [[String:Any]]()
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
                "value" : dpiWidth as! String
                ])
        }
    
        return array;
    }
    
    func parseExifMetadata(_ exifMetadata: [String: AnyObject], formattedMetadata: [[String:Any]]) {
        
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
            let aperture = String(format: "f/%@", fNumber as! String)
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

    func parseTiffMetadata(_ tiffMetadata: [String: AnyObject], formattedMetadata: [[String:Any]]) {
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

    func formatShutterSpeed(_ duration: Float) -> String {
        if duration > 1.0 { return String(format: "0.2f", duration) }
        let denominator = round(1.0/duration)
        return String(format: "1/%ld s", denominator)
    }

    func toBinary(_ input: Int) -> String {
        if input == 1 || input == 0 { return String(format: "%lu", input) }
        return String(format: "%@%lu", toBinary(input / 2), input % 2)
    }

    func formatDate(_ date: String) -> String {
        var components = date.components(separatedBy: " ")
        var month = ""
        var day = ""
        var year = ""
        
        if components.count >= 2 {
            let dateString = components[0];
            let timeString = components[1];
            
            components = dateString.components(separatedBy: ":")
            if components.count >= 3 {
                year = components[0];
                month = components[1];
                day = components[2];
            }
            
            components = timeString.components(separatedBy: ":")
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

    func title(_ orientation: UIImageOrientation) -> String {
        switch orientation {
        case .up:            return "Up";
        case .right:         return "90˚ CW";
        case .left:          return "90˚ CCW";
        case .down:          return "Up";
        case .rightMirrored: return "90˚ CW, Flipped";
        case .leftMirrored:  return "90˚ CCW, Flipped";
        default: return ""
        }
    }

}
