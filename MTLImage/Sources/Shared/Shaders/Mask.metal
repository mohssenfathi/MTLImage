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
    float dummy;
};

kernel void mask(texture2d<float, access::read>  inTexture       [[ texture(0) ]],
                 texture2d<float, access::write> outTexture      [[ texture(1) ]],
                 texture2d<float, access::read>  maskTexture     [[ texture(2) ]],
                 texture2d<float, access::read>  backgroundTexture [[ texture(3) ]],
                 constant MaskUniforms           &uniforms       [[ buffer(0)  ]],
                 uint2                           gid             [[thread_position_in_grid]])
{
  
    
    float4 color = inTexture.read(gid);
    float4 backgroundColor = backgroundTexture.read(gid);
//    float4 maskColor = maskTexture.read(gid);
//    float mask = dot(maskColor.rgb, float3(0.299, 0.587, 0.114));
    float mask = step(maskTexture.read(gid).r, 0.5);
    
    float4 newColor = float4(mix(color.rgb, backgroundColor.rgb, mask), 1.0);
    
    outTexture.write(newColor, gid);
    
}
