//
//  Mesh.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/18/18.
//

import Foundation
import MetalKit
import ARKit

@available(iOS 11.0, *)
public class Anchor: ARFilter {
    
    var mesh: MTKMesh
    
    public init(mesh: MTKMesh) {
        self.mesh = mesh
        super.init()
    }
    
    public override func reload() {
        super.reload()
        
        // TODO: Do something else
        guard let renderView = (finalTarget as? ARView)?.arView else { return }
        
        let anchorUniformBufferSize = kAlignedInstanceUniformsSize * kMaxBuffersInFlight

        let anchorGeometryVertexFunction = context.library?.makeFunction(name: "anchorGeometryVertexTransform")
        let anchorGeometryFragmentFunction = context.library?.makeFunction(name: "anchorGeometryFragmentLighting")
        
        anchorUniformBuffer = device.makeBuffer(length: anchorUniformBufferSize, options: .storageModeShared)
        anchorUniformBuffer.label = "AnchorUniformBuffer"
        
        let anchorPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        anchorPipelineStateDescriptor.label = "AnchorPipeline"
        anchorPipelineStateDescriptor.sampleCount = renderView.sampleCount
        anchorPipelineStateDescriptor.vertexFunction = anchorGeometryVertexFunction
        anchorPipelineStateDescriptor.fragmentFunction = anchorGeometryFragmentFunction
        anchorPipelineStateDescriptor.vertexDescriptor = geometryVertexDescriptor
        anchorPipelineStateDescriptor.colorAttachments[0].pixelFormat = renderView.colorPixelFormat
        anchorPipelineStateDescriptor.depthAttachmentPixelFormat = renderView.depthStencilPixelFormat
        anchorPipelineStateDescriptor.stencilAttachmentPixelFormat = renderView.depthStencilPixelFormat
        
        do {
            try anchorPipelineState = device.makeRenderPipelineState(descriptor: anchorPipelineStateDescriptor)
        } catch let error {
            print("Failed to created anchor geometry pipeline state, error \(error)")
        }
        
        let anchorDepthStateDescriptor = MTLDepthStencilDescriptor()
        anchorDepthStateDescriptor.depthCompareFunction = .less
        anchorDepthStateDescriptor.isDepthWriteEnabled = true
        anchorDepthState = device.makeDepthStencilState(descriptor: anchorDepthStateDescriptor)
        
    }
    
    public func place(at: Anchor) {
        
    }
    
    override func updateBuffers(at index: Int) {
        super.updateBuffers(at: index)
        
        anchorUniformBufferOffset = kAlignedInstanceUniformsSize * index
        anchorUniformBufferAddress = anchorUniformBuffer.contents().advanced(by: anchorUniformBufferOffset)
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        super.render(encoder: encoder)

        renderAnchorGeometry(encoder: encoder)
    }
    

    func renderAnchorGeometry(encoder: MTLRenderCommandEncoder) {
        guard anchorInstanceCount > 0 else {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        encoder.pushDebugGroup("DrawAnchors")
        
        // Set render command encoder state
        encoder.setCullMode(.back)
        encoder.setRenderPipelineState(anchorPipelineState)
        encoder.setDepthStencilState(anchorDepthState)
        
        // Set any buffers fed into our render pipeline
        encoder.setVertexBuffer(anchorUniformBuffer, offset: anchorUniformBufferOffset, index: BufferIndex.instanceUniforms.rawValue)
//        encoder.setVertexBuffer(sharedUniformBuffer, offset: sharedUniformBufferOffset, index: BufferIndex.sharedUniforms.rawValue)
//        encoder.setFragmentBuffer(sharedUniformBuffer, offset: sharedUniformBufferOffset, index: BufferIndex.sharedUniforms.rawValue)
        
        // Set mesh's vertex buffers
        for bufferIndex in 0 ..<hmesj.vertexBuffers.count {
            let vertexBuffer = mesh.vertexBuffers[bufferIndex]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index:bufferIndex)
        }
        
        // Draw each submesh of our mesh
        for submesh in cubeMesh.submeshes {
            encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: anchorInstanceCount)
        }
        
        encoder.popDebugGroup()
    }
    
    
    func updateAnchors(frame: ARFrame) {
        // Update the anchor uniform buffer with transforms of the current frame's anchors
        anchorInstanceCount = min(frame.anchors.count, kMaxAnchorInstanceCount)
        
        var anchorOffset: Int = 0
        if anchorInstanceCount == kMaxAnchorInstanceCount {
            anchorOffset = max(frame.anchors.count - kMaxAnchorInstanceCount, 0)
        }
        
        for index in 0..<anchorInstanceCount {
            let anchor = frame.anchors[index + anchorOffset]
            
            // Flip Z axis to convert geometry from right handed to left handed
            var coordinateSpaceTransform = matrix_identity_float4x4
            coordinateSpaceTransform.columns.2.z = -1.0
            
            let modelMatrix = simd_mul(anchor.transform, coordinateSpaceTransform)
            
            let anchorUniforms = anchorUniformBufferAddress.assumingMemoryBound(to: InstanceUniforms.self).advanced(by: index)
            anchorUniforms.pointee.modelMatrix = modelMatrix
        }
    }
    
    
    /// Private
    private var geometryVertexDescriptor: MTLVertexDescriptor!
    private var anchorUniformBufferAddress: UnsafeMutableRawPointer!
    private var anchorInstanceCount: Int = 0
    private var anchorUniformBufferOffset: Int = 0
    private var anchorUniformBuffer: MTLBuffer!
    private var anchorPipelineState: MTLRenderPipelineState!
    private var anchorDepthState: MTLDepthStencilState!
}
