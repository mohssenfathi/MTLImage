//
//  MTLLibrary.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/12/16.
//
//

import Metal

public
class MTLLib: NSObject {

    static let sharedLib = MTLLib()
    
    var library: MTLLibrary! = nil
    
//  TODO: Make throw
    class func sharedLibrary(device: MTLDevice) -> MTLLibrary? {
        
        if MTLLib.sharedLib.library == nil {
            let bundle = Bundle(for: MTLImage.classForCoder())
            guard let path = bundle.path(forResource: "default", ofType: "metallib") else {
                print("Cannot find metallib")
                return nil
            }
            
            do {
                MTLLib.sharedLib.library = try device.makeLibrary(filepath: path)
            }
            catch {
                print("Error creating metallib")
                return nil
            }
        }
        
        return MTLLib.sharedLib.library
    }
    
}
