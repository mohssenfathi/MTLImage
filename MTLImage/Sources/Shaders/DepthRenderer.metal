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
kernel void depthRenderer(texture2d<float, access::read>  inputTexture   [[ texture(0) ]],
                          texture2d<float, access::write> outputTexture  [[ texture(1) ]],
                          constant DepthRendererUniforms& uniforms       [[ buffer(0) ]],
                          uint2 gid [[ thread_position_in_grid ]])
{
    
//    float2 inputSize = float2(inputTexture.get_width(), inputTexture.get_height());
//    float2 outputSize = float2(outputTexture.get_width(), outputTexture.get_height());
//    float2 normalizedCoord = float2(float(gid.x)/inputSize.x, float(gid.y)/inputSize.y);
//    uint2 outputGid = uint2(normalizedCoord.x * outputSize.x, normalizedCoord.y * outputSize.y);
    
    float depth = inputTexture.read(gid).x;
    
    // Normalize the value between 0 and 1
//    depth = (depth - uniforms.offset) / (uniforms.range);
    
    outputTexture.write(float4(float3(depth), 1.0), gid);
}

