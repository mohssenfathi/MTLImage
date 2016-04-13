//
//  3x3Convolution.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void convolution(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        texture2d<float, access::read> convolutionMatrix [[ texture(2) ]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 centerColor      = inTexture.read(gid                        );
    float3 bottomColor      = inTexture.read(uint2(gid.x    , gid.y - 1)).rgb;
    float3 bottomLeftColor  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).rgb;
    float3 bottomRightColor = inTexture.read(uint2(gid.x + 1, gid.y - 1)).rgb;
    float3 leftColor        = inTexture.read(uint2(gid.x - 1, gid.y    )).rgb;
    float3 rightColor       = inTexture.read(uint2(gid.x + 1, gid.y    )).rgb;
    float3 topColor         = inTexture.read(uint2(gid.x    , gid.y + 1)).rgb;
    float3 topRightColor    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).rgb;
    float3 topLeftColor     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).rgb;
    
    float3 resultColor = topLeftColor  * convolutionMatrix.read(uint2(0, 0)).rrr +
                         topColor      * convolutionMatrix.read(uint2(0, 1)).rrr +
                         topRightColor * convolutionMatrix.read(uint2(0, 2)).rrr;
    
    resultColor += leftColor       * convolutionMatrix.read(uint2(1, 0)).rrr +
                   centerColor.rgb * convolutionMatrix.read(uint2(1, 1)).rrr +
                   rightColor      * convolutionMatrix.read(uint2(1, 2)).rrr;

    resultColor += bottomLeftColor  * convolutionMatrix.read(uint2(2, 0)).rrr +
                   bottomColor      * convolutionMatrix.read(uint2(2, 1)).rrr +
                   bottomRightColor * convolutionMatrix.read(uint2(2, 2)).rrr;
    
    outTexture.write(float4(resultColor, centerColor.a), gid);
}