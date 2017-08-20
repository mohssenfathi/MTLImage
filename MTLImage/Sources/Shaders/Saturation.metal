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

kernel void saturation(texture2d<float, access::read>  inTexture    [[ texture(0) ]],
                       texture2d<float, access::write> outTexture [[ texture(1) ]],
                       constant SaturationUniforms &uniforms        [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    float lum = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float4 satColor = float4(lum, lum, lum, color.a);
    
    outTexture.write(mix(satColor, color, uniforms.saturation), gid);
}