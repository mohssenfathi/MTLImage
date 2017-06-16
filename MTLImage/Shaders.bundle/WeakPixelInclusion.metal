//
//  WeakPixelInclusion.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct WeakPixelInclusionUniforms {
    
};

kernel void weakPixelInclusion(texture2d<float, access::read>  inTexture     [[ texture(0)]],
                               texture2d<float, access::write> outTexture    [[ texture(1)]],
                               constant WeakPixelInclusionUniforms &uniforms [[ buffer(0) ]],
                               uint2 gid [[thread_position_in_grid]])
{

    float center      = inTexture.read(gid                        ).r;
    float bottom      = inTexture.read(uint2(gid.x    , gid.y - 1)).r;
    float bottomLeft  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
    float bottomRight = inTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
    float left        = inTexture.read(uint2(gid.x - 1, gid.y    )).r;
    float right       = inTexture.read(uint2(gid.x + 1, gid.y    )).r;
    float top         = inTexture.read(uint2(gid.x    , gid.y + 1)).r;
    float topRight    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
    float topLeft     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
    
    float pixelSum = bottomLeft + topRight + topLeft + bottomRight + left + right + bottom + top + center;
    float sumTest = step(1.5, pixelSum);
    float pixelTest = step(0.01, center);
    
    outTexture.write(float4(float3(sumTest * pixelTest), 1.0), gid);
}