//
//  Image.swift
//  MTLImage_macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//

import Foundation
import MetalKit

public
class Image: NSObject, Input {
    
    public init(image: NSImage) {
        super.init()
        
        self.image = image
        self.textureLoader = MTKTextureLoader(device: context.device)
        context.source = self
        
        loadTexture()
    }
    
    // MARK: - Properties
    
    public var image: NSImage! {
        didSet {
            needsUpdate = true
            loadTexture()
        }
    }
    
    func loadTexture() {
        texture = image.texture(device: device)
        needsUpdate = false
    }
    
    
    // MARK: - Input
    public var title: String = "Image"
    public var id: String = UUID().uuidString
    public var needsUpdate: Bool = false
    public var continuousUpdate: Bool = false
    public var texture: MTLTexture?
    public var context: Context = Context()
    public var device: MTLDevice { return context.device }
    public var targets: [Output] = []
    public var commandBuffer: MTLCommandBuffer? {
        return context.commandQueue.makeCommandBuffer()
    }
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        loadTexture()
        t.input = self
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
        //      TODO:   remove from internalTargets
    }
    
    public func removeAllTargets() {
        targets.removeAll()
    }
    
    
    // MARK: - Private
    private var textureLoader: MTKTextureLoader!

}
