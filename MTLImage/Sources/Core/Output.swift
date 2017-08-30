//
//  Output.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/26/17.
//

public protocol Output {
    
    var input     : Input? { get set }
    var title     : String { get set }
    var identifier: String { get set }
}

public extension Output {
    
    public var source: Input? {
        get {
            var inp: Input? = input
            while inp != nil {
                
                if let sourcePicture = inp as? Picture {
                    return sourcePicture
                }
                
                #if !os(tvOS)
                    if let camera = inp as? Camera {
                        return camera
                    }
                #endif
                
                if inp is Output {
                    inp = (inp as? Output)?.input
                }
            }
            return nil
        }
    }
}

