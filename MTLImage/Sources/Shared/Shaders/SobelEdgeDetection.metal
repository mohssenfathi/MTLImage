//
//  SobelEdgeDetection.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SobelEdgeDetectionUniforms {
    float edgeStrength;
};

kernel void sobelEdgeDetection(texture2d<float, access::read>  inTexture     [[texture(0)]],
                               texture2d<float, access::write> outTexture    [[texture(1)]],
                               constant SobelEdgeDetectionUniforms &uniforms [[ buffer(0) ]],
                               uint2 gid [[thread_position_in_grid]])
{
    
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
    
    float magnitude = length(float2(h, v)) * uniforms.edgeStrength;
    
    outTexture.write(float4(float3(magnitude), 1.0), gid);
}