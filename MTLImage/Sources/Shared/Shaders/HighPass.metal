//
//  HighPass.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 9/14/17.
//

#include <metal_stdlib>
using namespace metal;

kernel void highPass(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     texture2d<float, access::read>  secondaryTexture [[ texture(2) ]],
                     uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float4 second = secondaryTexture.read(gid);
    float4 outputColor = float4(float3(color.rgb - second.rgb + float3(0.5, 0.5, 0.5)), color.a);
    outTexture.write(outputColor, gid);
}
