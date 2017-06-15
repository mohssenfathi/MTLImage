//
//  DepthBlend.metal
//  MTLImage_Example
//
//  Created by Mohssen Fathi on 6/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DepthBlendUniforms {
    float lowerThreshold;
};

// Compute kernel
kernel void depthBlend(texture2d<float, access::read>  inputTexture   [[ texture(0) ]],
                       texture2d<float, access::write> outputTexture  [[ texture(1) ]],
                       texture2d<float, access::read> depthTexture    [[ texture(2) ]],
                       texture2d<float, access::read> sourceTexture   [[ texture(3) ]],
                       constant DepthBlendUniforms& uniforms          [[ buffer(0) ]],
                       uint2 gid                                      [[ thread_position_in_grid ]])
{
    
    float2 depthSize = float2(depthTexture.get_width(), depthTexture.get_height());
    float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 normalizedCoord = float2(gid.x/texSize.x, gid.y/texSize.y);
    uint2 depthGid = uint2(normalizedCoord.x * depthSize.x, normalizedCoord.y * depthSize.y);
    
    float depth = depthTexture.read(depthGid).x;
    float4 texColor = inputTexture.read(gid);
    float4 sourceColor = sourceTexture.read(gid);
    
    if (depth < uniforms.lowerThreshold) {
        outputTexture.write(sourceColor, gid);
        return;
    }
    
    float4 color = float4(mix(sourceColor.rgb, texColor.rgb, depth), 1.0);
    outputTexture.write(color, gid);
}
