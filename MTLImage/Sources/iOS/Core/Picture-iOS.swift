//
//  Image.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import Photos
import MetalKit

public
class Picture: NSObject, Input {
    
    public var id: String = UUID().uuidString
    public var title: String = "Image"
    
    public var continuousUpdate: Bool {
        return false
    }

    var pipeline: MTLComputePipelineState!
    var textureLoader: MTKTextureLoader!
    
    deinit {
        removeAllTargets()
        image = nil
    }
    
    public var image: UIImage! {
        didSet {
            if processingSize == CGSize.zero {
                processingSize = image.size
            }
            loadTexture()
            needsUpdate = true
        }
    }
    
    public func setNeedsUpdate() {
        for target in targets {
            if let filter = target as? Filter {
                filter.needsUpdate = true
            }
        }
    }
    
    public var processingSize: CGSize! {
        didSet {
            loadTexture()
            context.processingSize = processingSize
        }
    }
    
    public func setProcessingSize(_ processingSize: CGSize, respectAspectRatio: Bool) {
        
        var size = processingSize
        if respectAspectRatio == true {
            if size.width > size.height {
                size.height = size.width / (image.size.width / image.size.height)
            }
            else {
                size.width = size.height * (image.size.width / image.size.height)
            }
        }
        
        self.processingSize = size
    }
    
    public init(image: UIImage) {
        super.init()
        
        self.title = "Image"
        self.image = image
        self.processingSize = image.size
        self.textureLoader = MTKTextureLoader(device: context.device)
        
        loadTexture()
        if #available(iOS 11.0, *) { loadDepthData() }
    }
    
    public init(asset: PHAsset) {
        fatalError("Needs to be implemented")
    }
    
    @available (iOS 11.0, *)
    func loadDepthData() {
        
        return 
        
        guard let cgImage = image.cgImage, let imageData = UIImageJPEGRepresentation(image, 1.0) else {
            return
        }
        
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return
        }
        
        guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDepth) as? [AnyHashable : Any] else {
            return
        }
        
        depthData = try? AVDepthData(fromDictionaryRepresentation: auxDataInfo)
    }
    
    func loadTexture() {

//        guard let cgImage = image.cgImage?.copy() else {
//            return
//        }
//        
//        let textureLoader = MTKTextureLoader(device: device)
//        textureLoader.newTexture(cgImage: cgImage, options: nil) { texture, error in
//            self.texture = texture
//        }
        
        texture = image.texture(device, flip: false, size: processingSize)
        
//        if let texture = image.texture(device, flip: false, size: processingSize) {
//            self.texture = texture.makeTextureView(pixelFormat: texture.pixelFormat)
//        }
        
    }
    
    func chainLength() -> Int {
//        Count only first target for now
        if targets.count == 0 { return 1 }
        let c = length(targets.first!)
        return c
    }
    
    func length(_ target: Output) -> Int {
        var c = 1
        
        if let input = target as? Input {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }

        return c
    }
    
//    MARK: - Input
    public var texture: MTLTexture?

    public var context: Context = Context()
    
    public var device: MTLDevice { return context.device }
    
    public var commandBuffer: MTLCommandBuffer? {
        return context.commandQueue?.makeCommandBuffer()
    }
    
    public var targets: [Output] = []
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
//        loadTexture()
    }
    
    public func removeTarget(_ target: Output) {
        
        guard let index = targets.enumerated().filter({ $0.element == target }).first?.offset else {
            return
        }
        
        var t = target
        t.input = nil
        targets.remove(at: index)
    }
    
    public func removeAllTargets() {
        for var target in targets { target.input = nil }
        targets.removeAll()
    }
    
    
    private var privateNeedsUpdate = true
    public var needsUpdate: Bool {
        set {
            privateNeedsUpdate = newValue
            if newValue == true {
                for target in targets {
                    if let filter = target as? Filter {
                        filter.needsUpdate = true
                    }
                    else if let view = target as? View {
                        view.setNeedsDisplay()
                    }
                }
            }
        }
        get {
            return privateNeedsUpdate
        }
    }
    
    
    public func didFinishProcessing() {
        context.semaphore.signal()
    }
    
    
    private var _depthData: Any?
    @available(iOS 11.0, *)
    public var depthData: AVDepthData? {
        get { return _depthData as? AVDepthData }
        set { _depthData = newValue }
    }
}
