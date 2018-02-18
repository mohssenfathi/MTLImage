//
//  ARFilter.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/18/18.
//

import ARKit

@available(iOS 11.0, *)
public class ARFilter: MTLObject {
 
    func updateBuffers(at index: Int) {
        (input as? ARFilter)?.updateBuffers(at: index)
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        (input as? ARFilter)?.render(encoder: encoder)
    }
    
}
