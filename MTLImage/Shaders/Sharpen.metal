//
//  Sharpen.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SharpenUniforms {
    float sharpness;
};

kernel void sharpen(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                    texture2d<float, access::write> outTexture [[ texture(1) ]],
                    constant SharpenUniforms &uniforms         [[ buffer(0) ]],
                    uint2 gid [[thread_position_in_grid]])
{
        
    float3 textureColor       = inTexture.read(gid).rgb;
    float3 leftTextureColor   = inTexture.read(uint2(gid.x - 1, gid.y    )).rgb;
    float3 rightTextureColor  = inTexture.read(uint2(gid.x + 1, gid.y    )).rgb;
    float3 topTextureColor    = inTexture.read(uint2(gid.x    , gid.y - 1)).rgb;
    float3 bottomTextureColor = inTexture.read(uint2(gid.x    , gid.y + 1)).rgb;
    
    float centerMultiplier = 1.0 + 4.0 * uniforms.sharpness * (1024.0/inTexture.get_width());
    float edgeMultiplier = uniforms.sharpness * (1024.0/inTexture.get_width());
    
    float4 color = float4(textureColor * centerMultiplier - (leftTextureColor * edgeMultiplier +
                                                             rightTextureColor * edgeMultiplier +
                                                             topTextureColor * edgeMultiplier +
                                                             bottomTextureColor * edgeMultiplier), inTexture.read(gid).a);
    outTexture.write(color, gid);
}