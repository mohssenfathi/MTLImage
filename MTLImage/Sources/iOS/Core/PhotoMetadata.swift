//
//  PhotoMetadata.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/7/17.
//

import Foundation

public
struct PhotoMetadata: Codable {
    
    var exif: Exif
    var tiff: Tiff
    var dpiWidth: Int
    var orientation: Int
    
    enum CodingKeys: String, CodingKey {
        case exif = "{Exif}"
        case tiff = "{TIFF}"
        case dpiWidth = "DPIWidth"
        case orientation = "Orientation"
    }
    
    init(metadata: [String : Any]) throws {
 
        let md = metadata.filter {
            if $0.value is Int { return true }
            return JSONSerialization.isValidJSONObject($0.value)
        }
        
        let json = try JSONSerialization.data(withJSONObject: md, options: .prettyPrinted)
        self = try JSONDecoder().decode(PhotoMetadata.self, from: json)
    }
}


public
struct Exif: Codable {
    
    var aperture: Double
    var brightness: Double
    var colorSpace: Int
//    var dateDigitized: String
//    var dateOriginal: String
    var exposureBias: Int
    var exposureMode: Int
    var exposureProgram: Int
    var exposureTime: Double
    var fNumber: Double
    var flash: Int
    var width: Int
    var height: Int
    var shutterSpeed: Double
    var lensMake: String
    var lensModel: String
    
    enum CodingKeys: String, CodingKey {
        case aperture = "ApertureValue"
        case brightness = "BrightnessValue"
        case colorSpace = "ColorSpace"
//        case dateDigitized = "DateTimeDigitized"
//        case dateOriginal = "DateTimeOriginal"
        case exposureBias = "ExposureBiasValue"
        case exposureMode = "ExposureMode"
        case exposureProgram = "ExposureProgram"
        case exposureTime = "ExposureTime"
        case fNumber = "FNumber"
        case flash = "Flash"
        case width = "PixelXDimension"
        case height = "PixelYDimension"
        case shutterSpeed = "ShutterSpeedValue"
        case lensMake = "LensMake"
        case lensModel = "LensModel"
    }
}

public
struct Tiff: Codable {
    
    var date: Date?
    var make: String
    var model: String
    var software: String
    var resolutionUnit: Int
    var xResolution: Int
    var yResolution: Int
    
    enum CodingKeys: String, CodingKey {
        case date = "DateTime"
        case make = "Make"
        case model = "Model"
        case software = "Software"
        case resolutionUnit = "ResolutionUnit"
        case xResolution = "XResolution"
        case yResolution = "YResolution"
    }
    
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Tiff.CodingKeys.self)
        
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY:MM:dd HH:mm:ss"
        date = dateFormatter.date(from: dateString)
        
        make = try container.decode(String.self, forKey: .make)
        model = try container.decode(String.self, forKey: .model)
        software = try container.decode(String.self, forKey: .software)
        resolutionUnit = try container.decode(Int.self, forKey: .resolutionUnit)
        xResolution = try container.decode(Int.self, forKey: .xResolution)
        yResolution = try container.decode(Int.self, forKey: .yResolution)
        
    }
}








