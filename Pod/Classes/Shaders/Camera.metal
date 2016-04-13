//
//  Camera.metal
//  Pods
//
//  Created by Mohssen Fathi on 4/12/16.
//
//

#include <metal_stdlib>
using namespace metal;

kernel void camera(texture2d<float, access::read> yTexture    [[texture(0)]],
                   texture2d<float, access::read> cbcrTexture [[texture(1)]],
                   texture2d<float, access::write> outTexture [[texture(2)]],
                   uint2 gid [[thread_position_in_grid]])
{

    float3   colorOffset = float3(-(16.0/255.0), -0.5, -0.5);
    float3x3 colorMatrix = float3x3(float3(1.164,  1.164, 1.164),
                                    float3(0.000, -0.392, 2.017),
                                    float3(1.596, -0.813, 0.000));

    uint2 cbcrCoordinates = uint2(gid.x / 2, gid.y / 2);
    float y = yTexture.read(gid).r;
    float2 cbcr = cbcrTexture.read(cbcrCoordinates).rg;
    float3 ycbcr = float3(y, cbcr);
    float3 rgb = colorMatrix * (ycbcr + colorOffset);

    outTexture.write(float4(float3(rgb), 1.0), gid);
}