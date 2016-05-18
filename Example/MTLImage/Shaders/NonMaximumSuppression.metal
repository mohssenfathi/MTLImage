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


struct NonMaximumSuppressionThresholdUniforms {
    float threshold;
};

kernel void nonMaximumSuppressionThreshold(texture2d<float, access::read>  inTexture                 [[ texture(0)]],
                                           texture2d<float, access::write> outTexture                [[ texture(1)]],
                                           constant NonMaximumSuppressionThresholdUniforms &uniforms [[ buffer(0) ]],
                                           uint2 gid [[thread_position_in_grid]])
{
    
    float4 center = inTexture.read(gid);
    
    float bottom      = inTexture.read(uint2(gid.x    , gid.y - 1)).r;
    float bottomLeft  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
    float bottomRight = inTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
    float left        = inTexture.read(uint2(gid.x - 1, gid.y    )).r;
    float right       = inTexture.read(uint2(gid.x + 1, gid.y    )).r;
    float top         = inTexture.read(uint2(gid.x    , gid.y + 1)).r;
    float topRight    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
    float topLeft     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
    
    // Use a tiebreaker for pixels to the left and immediately above this one
     float multiplier = 1.0 - step(center.r, top);
    multiplier = multiplier * (1.0 - step(center.r, topLeft));
    multiplier = multiplier * (1.0 - step(center.r, left));
    multiplier = multiplier * (1.0 - step(center.r, bottomLeft));
    
     float maxValue = max(center.r, bottom);
    maxValue = max(maxValue, bottomRight);
    maxValue = max(maxValue, right);
    maxValue = max(maxValue, topRight);
    
     float finalValue = center.r * step(maxValue, center.r) * multiplier;
    finalValue = step(uniforms.threshold, finalValue);
    
    outTexture.write(float4(finalValue, finalValue, finalValue, 1.0), gid);
}