//
//  DepthToGrayscale.metal
//  MTLImage_Example
//
//  Created by Mohssen Fathi on 6/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DepthRendererUniforms {
    float offset;
    float range;
};

// Compute kernel
kernel void depthRenderer(texture2d<float, access::read>  inputTexture      [[ texture(0) ]],
                             texture2d<float, access::write> outputTexture  [[ texture(1) ]],
                             constant DepthRendererUniforms& uniforms       [[ buffer(0) ]],
                             uint2 gid [[ thread_position_in_grid ]])
{
    // Ensure we don't read or write outside of the texture
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    float depth = inputTexture.read(gid).x;
    
    // Normalize the value between 0 and 1
//    depth = (depth - uniforms.offset) / (uniforms.range);
    
    outputTexture.write(float4(float3(depth), 1.0), gid);
}

