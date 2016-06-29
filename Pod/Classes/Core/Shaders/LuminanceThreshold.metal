//
//  LuminanceThreshold.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/24/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float3 W = float3(0.2125, 0.7154, 0.0721);
};

struct LuminanceThresholdUniforms {
    float threshold;
};

kernel void luminanceThreshold(texture2d<float, access::read>  inTexture     [[texture(0)]],
                               texture2d<float, access::write> outTexture    [[texture(1)]],
                               constant LuminanceThresholdUniforms &uniforms [[ buffer(0) ]],
                               uint2 gid                                     [[thread_position_in_grid]])
{
    Constants c;
    
    float4 color = inTexture.read(gid);
    float luminance = dot(color.rgb, c.W);
    float thresholdResult = step(uniforms.threshold, luminance);
    
    outTexture.write(float4(float3(thresholdResult), color.a), gid);
}