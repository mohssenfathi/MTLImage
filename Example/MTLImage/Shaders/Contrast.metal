//
//  Contrast.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ContrastUniforms {
    float contrast;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut contrastVertex(constant float4          *position  [[ buffer(0) ]],
                                  constant packed_float2    *texCoords [[ buffer(1) ]],
                                  constant ContrastUniforms &uniforms  [[ buffer(2) ]],
                                  uint                      vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 contrastFragment(VertexInOut               input     [[ stage_in ]],
                                texture2d<half>           tex2D     [[ texture(0) ]],
                                constant ContrastUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    return half4(((color.rgb - half3(0.5)) * uniforms.contrast + half3(0.5)), color.a);
}