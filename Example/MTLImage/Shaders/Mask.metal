//
//  Mask.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/16/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MaskUniforms {
    float brushSize;
    float x;
    float y;
};

kernel void mask(texture2d<float, access::read>  inTexture       [[ texture(0) ]],
                 texture2d<float, access::write> outTexture      [[ texture(1) ]],
                 texture2d<float, access::read>  maskTexture     [[ texture(2) ]],
                 texture2d<float, access::read>  originalTexture [[ texture(3) ]],
                 constant MaskUniforms           &uniforms       [[ buffer(0)  ]],
                 uint2                           gid             [[thread_position_in_grid]])
{
  
    
//    float4 color = inTexture.read(gid);
    
    float2 inSize   = float2(inTexture.get_width(), inTexture.get_height());
    float2 maskSize = float2(maskTexture.get_width(), maskTexture.get_height());
//    float2 point = float2(uniforms.x * inSize.x, uniforms.y * inSize.y);

    uint2 maskCoord = uint2(float(gid.x)/inSize.x * maskSize.x, float(gid.y)/inSize.y * maskSize.y);
    float m = maskTexture.read(maskCoord).r;
//    float4 originalColor = originalTexture.read(gid);

//    color = mix(originalColor, color, m);
    outTexture.write(float4(float3(m), 1.0), gid);
//    outTexture.write(color, gid);
    

    
//    float m = maskTexture.read(uint2(x,y)).r;
//    uint width = uint(uniforms.brushSize);
//    for (uint i = gid.x - width/2; i < gid.x + width/2; i++) {
//        for (uint j = gid.y - width/2; j < gid.y + width/2; j++) {
//            outTexture.write(float4(m, 0.0, 0.0, 1.0), uint2(i, j));
//        }
//    }
}
