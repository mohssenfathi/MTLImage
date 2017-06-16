//
//  DepthMask.metal
//  MTLImage_Example
//
//  Created by Mohssen Fathi on 6/6/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DepthMaskUniforms {
    float edgeStrength;
};

kernel void depthMask(texture2d<float, access::read>  inTexture     [[texture(0)]],
                      texture2d<float, access::write> outTexture    [[texture(1)]],
                      texture2d<float, access::write> depthMap      [[texture(2)]],
                      constant DepthMaskUniforms &uniforms          [[buffer(0)]],
                      uint2 gid                                     [[thread_position_in_grid]])
{
    outTexture.write(float4(0.0, 0.0, 1.0, 1.0), gid);
}
