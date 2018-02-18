//
//  FragFilter.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 11/22/17.
//

import Metal
import MetalKit

open
class RenderFilter: MTLObject {
  
    public override init() {
        super.init()
        setup()
    }
    
    func setup() {
        title = "Transform"
        reload()
    }
    
    override open func reload() {
        super.reload()
        
        // Functions
        vertexFunction   = context.library?.makeFunction(name: vertexName)
        fragmentFunction = context.library?.makeFunction(name: fragmentName)
        
        // Pipeline
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do      { pipeline = try device.makeRenderPipelineState(descriptor: descriptor) }
        catch   { fatalError(error.localizedDescription) }
        
    }
 
    open override func process() {

        input?.processIfNeeded()
        
        if texture == nil {
            initTexture()
        }
        
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer() else { return }
        
        autoreleasepool {
            
            encode(to: commandBuffer)
            
            commandBuffer.addCompletedHandler({ [weak self] (commandBuffer) in
                guard let weakSelf = self else { return }
//                weakSelf.didFinishProcessing(weakSelf)
//                weakSelf.newTextureAvailable?(weakSelf)
                if weakSelf.continuousUpdate || (weakSelf.input?.continuousUpdate ?? false) { return }
                self?.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        
    }
    
    
    func encode(to commandBuffer: MTLCommandBuffer) {
        
        guard let inputTexture = input?.texture else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = inputTexture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setFragmentTexture(inputTexture, index: 0)
        
        // For subclassing
        configureCommandEncoder(commandEncoder)
        
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        commandEncoder.endEncoding()
        
    }
    
    open func configureCommandEncoder(_ commandEncoder: MTLRenderCommandEncoder) {
        
    }
    
    
    public override var texture: MTLTexture? {
        get { return input?.texture }
        set { super.texture = newValue }
    }
    
    var vertexName: String {
        return "vertex_main"
    }
    var fragmentName: String {
        return "fragment_main"
    }
    
    var pipeline: MTLRenderPipelineState!
    
    /// Private
    private var vertexFunction: MTLFunction?
    private var fragmentFunction: MTLFunction?

}
