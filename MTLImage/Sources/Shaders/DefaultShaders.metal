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

vertex VertexInOut vertex_main(constant float4         *position   [[ buffer(0) ]],
                               constant packed_float2  *texCoords  [[ buffer(1) ]],
                               uint                     vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 fragment_main(VertexInOut        input    [[ stage_in ]],
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
