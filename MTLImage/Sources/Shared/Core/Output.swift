//
//  Output.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/26/17.
//

public protocol Output {
    
    var input : Input? { get set }
    var title : String { get set }
    var id    : String { get set }
}

public extension Output {
    
    public var source: Input? {
        get {
            var inp: Input? = input
            while inp != nil {
                
                // Picture
                #if os(macOS)
                    if let sourcePicture = inp as? Image {
                        return sourcePicture
                    }
                #else
                    if let sourcePicture = inp as? Picture {
                        return sourcePicture
                    }
                #endif
                
                
                // Camera
                #if !os(tvOS)
                    if let camera = inp as? Camera {
                        return camera
                    }
                #endif
                
                inp = (inp as? Output)?.input
            }
            return nil
        }
    }
}

func ==(left: Output, right: Output) -> Bool {
    return left.id == right.id
}
