//
//  Vignette.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VignetteUniforms {
    float x;
    float y;
    
    float r;
    float g;
    float b;
    
    float start;
    float end;
};

kernel void vignette(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant VignetteUniforms &uniforms        [[ buffer(0)  ]],
                     uint2 gid [[thread_position_in_grid]])
{
 
    float4 color = inTexture.read(gid);
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 point = float2(gid.x/size.x, gid.y/size.y);
    float2 center = float2(uniforms.x, uniforms.y);
    float d = distance(point, center);
    float percent = smoothstep(uniforms.start, uniforms.end, d);
    float3 vignetteColor = float3(uniforms.r, uniforms.g, uniforms.b);

    outTexture.write(float4(mix(color.rgb, vignetteColor, percent), color.a), gid);
}