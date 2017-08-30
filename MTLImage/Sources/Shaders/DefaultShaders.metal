//
//  Shaders.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/25/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float value;
};

struct VertexInOut {
    float4 pos      [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut vertex_main1(constant float4         *position   [[ buffer(0) ]],
                               constant packed_float2  *texCoords  [[ buffer(1) ]],
                               uint                     vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 fragment_main1(VertexInOut        input    [[ stage_in ]],
                             texture2d<half>    tex2D    [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    return tex2D.sample(quad_sampler, input.texCoord);
}

kernel void EmptyShader(texture2d<float, access::read>  inTexture     [[texture(0)]],
                        texture2d<float, access::write> outTexture    [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    outTexture.write(inTexture.read(gid), gid);
}


// -------------------------- //


typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex vertex_main(unsigned int vertex_id [[ vertex_id ]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),      /// (x, y, depth, W)
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));
    
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ), /// (x, y)
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 fragment_main(TextureMappingVertex mappingVertex [[ stage_in ]],
                             texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    return half4(texture.sample(s, mappingVertex.textureCoordinate));
}
