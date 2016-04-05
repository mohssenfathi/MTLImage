//
//  Saturation.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SaturationUniforms {
    float saturation;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut saturationVertex(constant float4             *position  [[ buffer(0) ]],
                                    constant packed_float2      *texCoords [[ buffer(1) ]],
                                    constant SaturationUniforms &uniforms  [[ buffer(2) ]],
                                    uint                        vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 saturationFragment(VertexInOut     input  [[ stage_in ]],
                                  texture2d<half> tex2D  [[ texture(0) ]],
                                  constant SaturationUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    
    half lum = dot(color.rgb, half3(0.30h, 0.59h, 0.11h));
    half4 satColor = half4(lum, lum, lum, color.a);
    
    color = half4(mix(satColor, color, half(uniforms.saturation)));
    
    return color;
}
