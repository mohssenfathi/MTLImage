//
//  UnsharpMask.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 6/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct UnsharpMaskUniforms {
    float intensity;
};

kernel void unsharpMask(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                        texture2d<float, access::write> outTexture  [[ texture(1) ]],
                        texture2d<float, access::read>  blurTexture [[ texture(2) ]],
                        constant UnsharpMaskUniforms &uniforms      [[ buffer(0) ]],
                        uint2 gid [[thread_position_in_grid]])
{

    float4 color     = inTexture.read(gid);
    float3 blurColor = blurTexture.read(gid).rgb;
    
    color = float4(color.rgb * uniforms.intensity + blurColor * (1.0 - uniforms.intensity), color.a);
    
    outTexture.write(color, gid);
}
