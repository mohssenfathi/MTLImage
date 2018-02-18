//
//  ShaderTypes.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/18/18.
//

import Foundation
import Metal
import MetalKit

// TODO: This was originally a shared header. Caused issues with Cocoapods. Eventually we need to figure out how to include a ShaderTypes.h in the framework. For now, just make sure these indexed match the struct in the shader file.

enum BufferIndex: Int {
    case meshPositions
    case meshGenerics
    case instanceUniforms
    case sharedUniforms
}

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices

enum VertexAttributes: Int {
    case position
    case texcoord
    case normal
}

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls

enum TextureIndex: Int {
    case color
    case Y
    case CbCr
}

// Structure shared between shader and C code to ensure the layout of shared uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
struct SharedUniforms: Uniforms {
    
    // Camera Uniforms
    var projectionMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    
    // Lighting Properties
    var ambientLightColor: vector_float3
    var directionalLightDirection: vector_float3
    var directionalLightColor: vector_float3
    var materialShininess: Float
}

// Structure shared between shader and C code to ensure the layout of instance uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
struct InstanceUniforms: Uniforms {
    var modelMatrix: matrix_float4x4
}
