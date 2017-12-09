//
//  Transform.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 11/25/17.
//

import UIKit
import MetalKit

struct TransformUniforms: Uniforms {
    var transform: float4x4 = float4x4(
        float4(1, 0, 0, 0),
        float4(0, 1, 0, 0),
        float4(0, 0, 1, 0),
        float4(0, 0, 0, 1)
    )
}

class Transform: RenderFilter {
    
    var uniforms = TransformUniforms()
    var transform: CGAffineTransform = CGAffineTransform(scaleX: 0.5, y: 0.5)

    override func update() {
        super.update()
        
        uniforms.transform = float4x4(
            float4(Float(transform.a) , Float(transform.b) , 0, 0),
            float4(Float(transform.c) , Float(transform.d) , 0, 0),
            float4(Float(transform.tx), Float(transform.ty), 1, 0),
            float4(0                  , 0                  , 0, 1)
        )

        vertexBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<TransformUniforms>.size, options: .storageModeShared)
    }

    
    override func configureCommandEncoder(_ commandEncoder: MTLRenderCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    }
    
    override var vertexName: String {
        return "transform_vertex"
    }
    
    
    private var vertexBuffer: MTLBuffer?
}
