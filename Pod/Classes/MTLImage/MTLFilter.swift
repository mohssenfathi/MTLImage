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

public
class MTLFilter: NSObject, MTLInput, MTLOutput {
    
    var internalTexture: MTLTexture?
    var privateInput: MTLInput!
    var pipeline: MTLRenderPipelineState!
    var dirty: Bool!
    var functionName: String!
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var kernelFunction: MTLFunction!
    
    var vertexBuffer: MTLBuffer?
    var texCoordBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    
    private var internalTargets = [MTLOutput]()
    var sourcePicture: MTLPicture? {
        get {
            var inp: MTLInput? = input
            while inp != nil {
                if let sourcePicture = input as? MTLPicture {
                    return sourcePicture
                }
            }
            return nil
        }
    }
    
    public var title: String!
    public var properties: [MTLProperty]!
    public var originalImage: UIImage? {
        get {
            return sourcePicture?.image
        }
    }
    
    public var image: UIImage {
        get {
            if dirty == true {
                process()
            }
            return UIImage.imageWithTexture(texture!)
        }
    }
    
    public init(functionName: String) {
        super.init()
        self.functionName = functionName
    }
    
    func update() {
        
    }
    
    func setupPipeline() {
        
        vertexFunction   = context.library?.newFunctionWithName(functionName + "Vertex")
        fragmentFunction = context.library?.newFunctionWithName(functionName + "Fragment")
//        kernelFunction = context.library?.newFunctionWithName(functionName)
        
        if vertexFunction == nil {
            print("Couldn't load vertex function")
            vertexFunction = context.library?.newFunctionWithName("vertex_main")
        }
        if fragmentFunction == nil {
            print("Couldn't load fragment function")
            fragmentFunction = context.library?.newFunctionWithName("fragment_main")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.RGBA8Unorm
        pipelineDescriptor.vertexFunction   = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
//            pipeline = try context.device.newComputePipelineStateWithFunction(fragmentFunction)
            pipeline = try context.device?.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
        
        dirty = true
    }
    
    func setupBuffers() {
        
        let kCntQuadTexCoords = 6;
        let kSzQuadTexCoords  = kCntQuadTexCoords * sizeof(float2);
        
        let kCntQuadVertices = kCntQuadTexCoords;
        let kSzQuadVertices  = kCntQuadVertices * sizeof(float4);
        
        
        let kQuadVertices: [float4] = [
            float4(-1.0, -1.0, 0.0, 1.0),
            float4( 1.0, -1.0, 0.0, 1.0),
            float4(-1.0,  1.0, 0.0, 1.0),
            
            float4( 1.0, -1.0, 0.0, 1.0),
            float4(-1.0,  1.0, 0.0, 1.0),
            float4( 1.0,  1.0, 0.0, 1.0) ]
        
        let kQuadTexCoords: [float2] = [
            float2(0.0, 0.0),
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            float2(1.0, 1.0) ]
        
        vertexBuffer   = device.newBufferWithBytes(kQuadVertices , length: kSzQuadVertices , options: .CPUCacheModeDefaultCache)
        texCoordBuffer = device.newBufferWithBytes(kQuadTexCoords, length: kSzQuadTexCoords, options: .CPUCacheModeDefaultCache)
    }

    var semaphore = dispatch_semaphore_create(1)
    
    public func process() {
        
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
//        runAsynchronously {
            if self.input == nil {
//                dispatch_semaphore_signal(self.semaphore)
                return
            }
            
            guard let inputTexture = self.input?.texture else {
                print("input texture nil")
//                dispatch_semaphore_signal(self.semaphore)
                return
            }
            
            if self.internalTexture == nil || self.internalTexture!.width != inputTexture.width || self.internalTexture!.height != inputTexture.height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat, width:inputTexture.width, height: inputTexture.height, mipmapped: false)
                self.internalTexture = self.context.device?.newTextureWithDescriptor(textureDescriptor)
                
                // Maybe recreate buffers
                self.setupBuffers()
            }
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = self.internalTexture
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
            renderPassDescriptor.colorAttachments[0].storeAction = .Store
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            
            let commandBuffer = self.context.commandQueue.commandBuffer()
            let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            commandEncoder.setRenderPipelineState(self.pipeline)
            
            commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
            commandEncoder.setVertexBuffer(self.texCoordBuffer, offset: 0, atIndex: 1)
            commandEncoder.setVertexBuffer(self.uniformsBuffer, offset: 0, atIndex: 2)
            
            commandEncoder.setFragmentTexture(inputTexture, atIndex: 0)
            commandEncoder.setFragmentBuffer(self.uniformsBuffer, offset: 0, atIndex: 1)
            configureCommandEncoder(commandEncoder)
            commandEncoder.drawPrimitives(.Triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
            commandEncoder.endEncoding()
            
            commandBuffer.commit()
//            dispatch_semaphore_signal(self.semaphore)
            commandBuffer.waitUntilCompleted()
//        }
        
        
        
//        guard let inputTexture = self.input?.texture else {
//            print("input texture nil")
//            return
//        }
//        
//        if self.internalTexture == nil || self.internalTexture!.width != inputTexture.width || self.internalTexture!.height != inputTexture.height {
//            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat, width:inputTexture.width, height: inputTexture.height, mipmapped: false)
//            self.internalTexture = self.context.device?.newTextureWithDescriptor(textureDescriptor)
//
//            // Maybe recreate buffers
//            self.setupBuffers()
//        }
//        
//        let threadgroupCounts = MTLSizeMake(8, 8, 1)
//        let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width,
//                                       inputTexture.height / threadgroupCounts.height, 1)
//        
//        let commandBuffer = self.context.commandQueue.commandBuffer()
//        let commandEncoder = commandBuffer.computeCommandEncoder()
//        commandEncoder.setComputePipelineState(pipeline)
//        commandEncoder.setTexture(inputTexture, atIndex: 0)
//        commandEncoder.setTexture(internalTexture, atIndex: 1)
//        configureCommandEncoder(commandEncoder)
//        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
//        commandEncoder.endEncoding()
//        
//        commandBuffer.commit()
//        commandBuffer.waitUntilCompleted()
    }
    
    
    func configureCommandEncoder(commandEncoder: MTLRenderCommandEncoder) {
        
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
        dispatch_async(context.processingQueue) { 
            block()
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
            return (self.input?.context)!
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
    
    public func addTarget(var target: MTLOutput) {
        internalTargets.append(target)
        target.input = self
        sourcePicture?.loadTexture()
    }
    
    public func removeTarget(var target: MTLOutput) {
        target.input = nil
//      TODO:   remove from internalTargets
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
            return self.privateInput
        }
        set {
            privateInput = newValue
            if newValue != nil {
                setupPipeline()
                setupBuffers()
                update()
            }
        }
    }
}
