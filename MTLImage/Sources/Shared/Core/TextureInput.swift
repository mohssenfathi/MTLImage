//
//  TextureInput.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/20/18.
//

import Foundation


public
class TextureInput: Input {
    
    public var targets: [Output] = []
    public var context: Context
    public var device: MTLDevice
    public var title: String = "Texture Stream"
    public var id: String = UUID().uuidString
    public var needsUpdate: Bool = true
    public var continuousUpdate: Bool = false
    public var textureProvider: (() -> (MTLTexture?))
    public var pixelBufferProvider: (() -> (CVPixelBuffer?))?
    public var texture: MTLTexture? {
        get { return textureProvider() }
        set {  }
    }
    
    public init(textureProvider: @escaping (() -> (MTLTexture?))) {
        self.textureProvider = textureProvider
        context = Context()
        device = context.device
    }
    
    public init(textureProvider: @escaping (() -> (MTLTexture?)), pixelBufferProvider: @escaping (() -> (CVPixelBuffer?))) {
        self.textureProvider = textureProvider
        self.pixelBufferProvider = pixelBufferProvider
        context = Context()
        device = context.device
    }
}


// Not sure why its making us reimplement this
extension TextureInput {
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
    }
    
    public func removeAllTargets() {
        targets.removeAll()
    }
}


extension TextureInput: DepthInput {
    
    public var depthPixelBuffer: CVPixelBuffer? {
        return pixelBufferProvider?()
    }
}

