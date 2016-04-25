//
//  Saturation.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PolkaDotUniforms {
    float dotRadius;
};

kernel void polkaDot(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant PolkaDotUniforms &uniforms        [[ buffer(0) ]],
                     uint2 gid [[thread_position_in_grid]])
{
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 index = float2(gid);
    float radius = uniforms.dotRadius * size.x/10.0;
    float2 closestCenter =  index - fmod(index, radius * 2.5) + radius;
    float dist = distance(float2(gid), closestCenter);
    float within = step(dist, radius);
    float4 color = inTexture.read(uint2(closestCenter));
    outTexture.write(float4(color.rgb * within, color.a), gid);
}