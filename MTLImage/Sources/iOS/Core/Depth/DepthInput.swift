//
//  DepthInput.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/27/18.
//

import Foundation

public protocol DepthInput {
    var depthPixelBuffer: CVPixelBuffer? { get }
    var depthTextureSize: CGSize? { get }
}

extension DepthInput {
    
    public var depthTextureSize: CGSize? {
        guard let pb = depthPixelBuffer else { return nil }
        let width = CVPixelBufferGetWidth(pb)
        let height = CVPixelBufferGetHeight(pb)
        return CGSize(width: width, height: height)
    }
}
