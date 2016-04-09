//
//  Pixellate.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/1/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PixellateUniforms {
    float dotRadius;
    float aspectRatio;
    float fractionalWidthOfPixel;
};

kernel void pixellate(texture2d<float, access::read>  inTexture [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant PixellateUniforms &uniforms       [[ buffer(0) ]],
                     uint2 gid [[thread_position_in_grid]])
{
    
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 texCoord = float2(gid.x/size.x, gid.y/size.y);
    float aspectRatio = size.y / size.x;
    
    float width = uniforms.fractionalWidthOfPixel * uniforms.dotRadius; 
    float2 sampleDivisor = float2(width, width / aspectRatio);
    float2 samplePos = texCoord - fmod(texCoord, sampleDivisor) + 0.5 * sampleDivisor;
    uint2 sp = uint2(samplePos.x * size.x, samplePos.y * size.y);
    
    outTexture.write(inTexture.read(sp), gid);
}