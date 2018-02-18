//
//  ShaderTypes.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 2/18/18.
//

#include <metal_stdlib>
using namespace metal;

//struct BufferIndices {
//    int kBufferIndexMeshPositions    = 0;
//    int kBufferIndexMeshGenerics     = 1;
//    int kBufferIndexInstanceUniforms = 2;
//    int kBufferIndexSharedUniforms   = 3;
//};
//
//struct VertexAttributes {
//    int kVertexAttributePosition  = 0;
//    int kVertexAttributeTexcoord  = 1;
//    int kVertexAttributeNormal    = 2;
//};
//
//struct TextureIndices {
//    int kTextureIndexColor    = 0;
//    int kTextureIndexY        = 1;
//    int kTextureIndexCbCr     = 2;
//};

struct SharedUniforms {
    // Camera Uniforms
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    
    // Lighting Properties
    float3 ambientLightColor;
    float3 directionalLightDirection;
    float3 directionalLightColor;
    float materialShininess;
};

struct InstanceUniforms {
    float4x4 modelMatrix;
};

