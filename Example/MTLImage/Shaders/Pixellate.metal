//
//  Pixellate.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/1/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PixellateUniforms {
    float dotRadius;
    float aspectRatio;
    float fractionalWidthOfPixel;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut pixellateVertex(constant float4           *position  [[ buffer(0) ]],
                                  constant packed_float2     *texCoords [[ buffer(1) ]],
                                  constant PixellateUniforms &uniforms  [[ buffer(2) ]],
                                  uint                       vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 pixellateFragment(VertexInOut    input  [[ stage_in ]],
                                texture2d<half> tex2D  [[ texture(0) ]],
                                constant PixellateUniforms &uniforms [[buffer(1)]])
{
    
    constexpr sampler quad_sampler;

    float width = uniforms.fractionalWidthOfPixel * uniforms.dotRadius;
    float2 sampleDivisor = float2(width, width / uniforms.aspectRatio);
    float2 samplePos = input.texCoord - fmod(input.texCoord, sampleDivisor) + 0.5 * sampleDivisor;
    
    return tex2D.sample(quad_sampler, samplePos);
}
