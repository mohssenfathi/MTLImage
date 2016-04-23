//
//  MTLFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit
import Metal
import MetalKit

func ==(left: MTLFilter, right: MTLFilter) -> Bool {
    return left.identifier == right.identifier
}

public
class MTLFilter: NSObject, MTLInput, MTLOutput {
    
    private var internalTargets = [MTLOutput]()
    private var internalTexture: MTLTexture?
    var internalInput: MTLInput?
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    var vertexBuffer: MTLBuffer?
    var texCoordBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var index: Int = 0
    
    public init(functionName: String) {
        super.init()
        self.functionName = functionName
    }
    
    var internalTitle: String!
    public var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = NSUUID().UUIDString
    public var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    var dirty: Bool = true {
        didSet {
            if dirty == true { setNeedsUpdate() }
        }
    }
    var semaphore = dispatch_semaphore_create(1)
    
    var source: MTLInput? {
        get {
            var inp: MTLInput? = input
            while inp != nil {
                if let sourcePicture = inp as? MTLPicture {
                    return sourcePicture
                }
                if let camera = inp as? MTLCamera {
                    return camera
                }
                else if let filter = inp as? MTLFilter {
                    inp = filter.input
                }
                else if let filterGroup = inp as? MTLFilterGroup {
                    inp = filterGroup.input
                }
            }
            return nil
        }
    }
    
    var outputView: MTLView? {
        get {
            // This only checks first target for now. Do DFS later
            var out: MTLOutput? = targets.first
            while out != nil {
                if let filter = out as? MTLFilter {
                    out = filter.targets.first
                }
                else if let filterGroup = out as? MTLFilterGroup {
                    out = filterGroup.targets.first
                }
                else if let mtlView = out as? MTLView {
                    return mtlView
                }
            }
            return nil
        }
    }
    
    var functionName: String!
    public var properties = [MTLProperty]()
    
    public var originalImage: UIImage? {
        get {
            if let picture = source as? MTLPicture {
                return picture.image
            }
            return nil
        }
    }
    
    public var image: UIImage {
        get {
            if dirty == true {
                process()
            }
            return UIImage.imageWithTexture(texture!)!
        }
    }
    
    func update() {
        
    }
    
    public func reset() {
        for property in properties {
            if property.propertyType == MTLPropertyType.Value {
                self.setValue(0.5, forKey: property.key)
            }
        }
    }
    
    public func setNeedsUpdate() {
        for target in targets {
            if let filter = target as? MTLFilter {
                filter.dirty = true
            }
        }
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.newFunctionWithName(functionName)
        if kernelFunction == nil {
            print("Failed to load kernel function")
            return
        }

        do {
            pipeline = try context.device.newComputePipelineStateWithFunction(kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    public func process() {
        
        guard let inputTexture = self.input?.texture else {
            print("input texture nil")
            return
        }
        
        runSynchronously {
            if self.internalTexture == nil || self.internalTexture!.width != inputTexture.width || self.internalTexture!.height != inputTexture.height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat, width:inputTexture.width, height: inputTexture.height, mipmapped: false)
                self.internalTexture = self.context.device?.newTextureWithDescriptor(textureDescriptor)
            }
            
            let threadgroupCounts = MTLSizeMake(8, 8, 1)
            let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width,
                                           inputTexture.height / threadgroupCounts.height, 1)
            
            let commandBuffer = self.context.commandQueue.commandBuffer()
            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(self.pipeline)
            commandEncoder.setBuffer(self.uniformsBuffer, offset: 0, atIndex: 0)
            commandEncoder.setTexture(inputTexture, atIndex: 0)
            commandEncoder.setTexture(self.internalTexture, atIndex: 1)
            self.configureCommandEncoder(commandEncoder)
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
            commandEncoder.endEncoding()
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            self.dirty = false
        }
    }
    
    func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        
    }
    
    //    MARK: - Tools
    
    func clamp<T: Comparable>(inout value: T, low: T, high: T) {
        if      value < low  { value = low  }
        else if value > high { value = high }
    }
    
    
    //    MARK: - Queues
    
    func runSynchronously(block: (()->())) {
        dispatch_sync(context.processingQueue) {
            block()
        }
    }
    
    func runAsynchronously(block: (()->())) {
        //        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        dispatch_async(context.processingQueue) {
            block()
            //            dispatch_semaphore_signal(self.semaphore)
        }
    }
    
    
    //    MARK: - MTLInput
    
    public var texture: MTLTexture? {
        get {
            if dirty == true {
                process()
            }
            return internalTexture
        }
    }
    
    public var context: MTLContext {
        get {
            if internalInput != nil {
                return internalInput!.context
            }
            return MTLContext()
        }
    }
    
    public var device: MTLDevice {
        get {
            return context.device
        }
    }
    
    public var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    public func addTarget(target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        t.input = self
        if let picture = source as? MTLPicture {
            picture.loadTexture()
        }
    }
    
    public func removeTarget(target: MTLOutput) {
        var t = target
        
        t.input = nil
        
        var index: Int!
        if let filter = target as? MTLFilter {
            for i in 0 ..< internalTargets.count {
                if let f = internalTargets[i] as? MTLFilter {
                    if f == filter { index = i }
                }
            }
        }
        else if t is MTLView {
            for i in 0 ..< internalTargets.count {
                if internalTargets[i] is MTLView { index = i }
            }
        }
        
        internalTargets.removeAtIndex(index)
        internalTexture = nil
    }
    
    public func removeAllTargets() {
        for var target in internalTargets {
            target.input = nil
        }
        internalTargets.removeAll()
    }
    
    
    //    MARK: - MTLOutput
    
    public var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            if newValue != nil {
                internalInput = newValue
                setupPipeline()
                update()
            }
        }
    }
}