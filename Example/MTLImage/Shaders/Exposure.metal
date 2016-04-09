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

kernel void exposure(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant ExposureUniforms &uniforms        [[ buffer(0) ]],
                     uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    outTexture.write(float4(color.rgb * pow(2.0, uniforms.exposure), color.a), gid);
}