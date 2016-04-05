//
//  Exposure.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/1/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ExposureUniforms {
    float exposure;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut exposureVertex(constant float4           *position  [[ buffer(0) ]],
                                   constant packed_float2     *texCoords [[ buffer(1) ]],
                                   constant ExposureUniforms &uniforms  [[ buffer(2) ]],
                                   uint                       vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 exposureFragment(VertexInOut    input  [[ stage_in ]],
                                 texture2d<half> tex2D  [[ texture(0) ]],
                                 constant ExposureUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    return half4(color.rgb * pow(2.0, uniforms.exposure), color.a);
}

