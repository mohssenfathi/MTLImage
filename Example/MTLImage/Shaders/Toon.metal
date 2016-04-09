//
//  Toon.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ToonUniforms {
    float quantizationLevels;
    float threshold;
};

kernel void toon(texture2d<float, access::read>  inTexture  [[texture(0)]],
                 texture2d<float, access::write> outTexture [[texture(1)]],
                 constant ToonUniforms &uniforms            [[ buffer(0) ]],
                 uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    
    float bottomLeftIntensity  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
    float topRightIntensity    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
    float topLeftIntensity     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
    float bottomRightIntensity = inTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
    float leftIntensity        = inTexture.read(uint2(gid.x - 1, gid.y + 0)).r;
    float rightIntensity       = inTexture.read(uint2(gid.x + 1, gid.y + 0)).r;
    float bottomIntensity      = inTexture.read(uint2(gid.x + 0, gid.y - 1)).r;
    float topIntensity         = inTexture.read(uint2(gid.x + 0, gid.y + 1)).r;
    
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float mag = length(float2(h, v));
    float3 posterizedImageColor = floor((color.rgb * uniforms.quantizationLevels) + 0.5) / uniforms.quantizationLevels;
    float thresholdTest = 1.0 - step(uniforms.threshold, mag);
    
    outTexture.write(float4(posterizedImageColor * thresholdTest, color.a), gid);
}
