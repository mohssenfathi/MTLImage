//
//  NonMaximumSuppression.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct NonMaximumSuppressionUniforms {
    float texelWidth;
    float texelHeight;
    float lowerThreshold;
    float upperThreshold;
};

kernel void nonMaximumSuppression(texture2d<float, access::read>  inTexture        [[ texture(0)]],
                                  texture2d<float, access::write> outTexture       [[ texture(1)]],
                                  constant NonMaximumSuppressionUniforms &uniforms [[ buffer(0) ]],
                                  uint2 gid [[thread_position_in_grid]])
{
    
    float3 currentGradientAndDirection = inTexture.read(gid).rgb;
    float2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * float2(uniforms.texelWidth, uniforms.texelHeight);
    
    float firstSampledGradientMagnitude = inTexture.read(gid + uint2(gradientDirection)).r;
    float secondSampledGradientMagnitude = inTexture.read(gid - uint2(gradientDirection)).r;
    
    float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
    multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);
    
    float thresholdCompliance = smoothstep(uniforms.lowerThreshold, uniforms.upperThreshold, currentGradientAndDirection.r);
    multiplier = multiplier * thresholdCompliance;
    
    outTexture.write(float4(multiplier, multiplier, multiplier, 1.0), gid);
}