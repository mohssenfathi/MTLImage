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
    float3 warmFilter = float3(0.93, 0.54, 0.0);
    float3x3 RGBtoYIQ = float3x3(float3(0.299, 0.587, 0.114), float3(0.596, -0.274, -0.322), float3(0.212, -0.523, 0.311));
    float3x3 YIQtoRGB = float3x3(float3(1.000, 0.956, 0.621), float3(1.000, -0.272, -0.647), float3(1.000, -1.105, 1.702));
};

kernel void whiteBalance(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                         texture2d<float, access::write> outTexture [[ texture(1) ]],
                         constant WhiteBalanceUniforms &uniforms    [[ buffer(0) ]],
                         uint2    gid                               [[thread_position_in_grid]])
{

    Constants c;
    float4 color = inTexture.read(gid);
    
    float3 yiq = c.RGBtoYIQ * color.rgb;
    yiq.b = clamp(yiq.b + uniforms.tint * 0.5226 * 0.1, -0.5226, 0.5226);
    float3 rgb = c.YIQtoRGB * yiq;
    
    float3 processed = float3((rgb.r < 0.5 ? (2.0 * rgb.r * c.warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - c.warmFilter.r))),
                              (rgb.g < 0.5 ? (2.0 * rgb.g * c.warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - c.warmFilter.g))),
                              (rgb.b < 0.5 ? (2.0 * rgb.b * c.warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - c.warmFilter.b))));
    
    outTexture.write(float4(mix(rgb, processed, uniforms.temperature), color.a), gid);
}

