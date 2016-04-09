//
//  Haze.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct HazeUniforms {
    float distance;
    float slope;
};

kernel void haze(texture2d<float, access::read>  inTexture  [[texture(0)]],
                 texture2d<float, access::write> outTexture [[texture(1)]],
                 constant HazeUniforms &uniforms            [[ buffer(0) ]],
                 uint2 gid [[thread_position_in_grid]])
{

    float4 color = float4(1.0);
    float d = gid.y/inTexture.get_height() * uniforms.slope + uniforms.distance;
    float4 c = inTexture.read(gid);
    c = (c - d * color) / (1.0 - d);

    outTexture.write(c, gid);
}