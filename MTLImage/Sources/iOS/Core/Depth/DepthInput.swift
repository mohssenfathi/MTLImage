//
//  DepthInput.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/27/18.
//

import Foundation

@available(iOS 11.0, *)
public protocol DepthInput {
    var depthPixelBuffer: CVPixelBuffer? { get }
    var depthTextureSize: CGSize? { get }
}

@available(iOS 11.0, *)
extension DepthInput {
    
    public var depthTextureSize: CGSize? {
        guard let pb = depthPixelBuffer else { return nil }
        let width = CVPixelBufferGetWidth(pb)
        let height = CVPixelBufferGetHeight(pb)
        return CGSize(width: width, height: height)
    }
}
