//
//  WhiteBalance.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct WhiteBalanceUniforms {
    float temperature;
    float tint;
};

struct Constants {
    half3 warmFilter = half3(0.93, 0.54, 0.0);
    half3x3 RGBtoYIQ = half3x3(half3(0.299, 0.587, 0.114), half3(0.596, -0.274, -0.322), half3(0.212, -0.523, 0.311));
    half3x3 YIQtoRGB = half3x3(half3(1.000, 0.956, 0.621), half3(1.000, -0.272, -0.647), half3(1.000, -1.105, 1.702));
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut whiteBalanceVertex(constant float4           *position  [[ buffer(0) ]],
                                  constant packed_float2        *texCoords [[ buffer(1) ]],
                                  constant WhiteBalanceUniforms &uniforms  [[ buffer(2) ]],
                                  uint                          vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 whiteBalanceFragment(VertexInOut               input     [[ stage_in ]],
                                    texture2d<half>               tex2D     [[ texture(0) ]],
                                    constant WhiteBalanceUniforms &uniforms [[buffer(1)]])
{
    Constants c;
    
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    
    half3 yiq = c.RGBtoYIQ * color.rgb;
    yiq.b = clamp(yiq.b + uniforms.tint * 0.5226 * 0.1, -0.5226, 0.5226);
    half3 rgb = c.YIQtoRGB * yiq;
    
    half3 processed = half3((rgb.r < 0.5 ? (2.0 * rgb.r * c.warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - c.warmFilter.r))),
                            (rgb.g < 0.5 ? (2.0 * rgb.g * c.warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - c.warmFilter.g))),
                            (rgb.b < 0.5 ? (2.0 * rgb.b * c.warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - c.warmFilter.b))));
    
    return half4(mix(rgb, processed, half(uniforms.temperature)), color.a);
}



