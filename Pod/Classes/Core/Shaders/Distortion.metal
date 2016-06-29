//
//  Distortion.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DistortionUniforms {
    float centerX;
    float centerY;
};

kernel void distortion(texture2d<float, access::read>  inTexture  [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       constant DistortionUniforms &uniforms      [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
    float2 texCoord  = float2(gid) / textureSize;
    
    float2 center = float2(uniforms.centerX, uniforms.centerY);
    float2 normCoord  = texCoord;
    float2 normCenter = center;
    
    normCoord -= normCenter;
    float2 s = sign(normCoord);
    normCoord = abs(normCoord);
    normCoord = 0.5 * normCoord + 0.5 * smoothstep(0.25, 0.5, normCoord) * normCoord;
    normCoord = s * normCoord;
    
    normCoord += normCenter;
    normCoord = float2(normCoord.x * textureSize.x, normCoord.y * textureSize.y);
    
    uint2 textureCoordinateToUse = uint2(normCoord + 0.5);
    
    outTexture.write(color, textureCoordinateToUse);
}