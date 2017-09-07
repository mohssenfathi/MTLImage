//
//  Camera.metal
//  Pods
//
//  Created by Mohssen Fathi on 4/12/16.
//
//

#include <metal_stdlib>
using namespace metal;

kernel void camera(texture2d<float, access::read> inTexture   [[texture(0)]],
                   texture2d<float, access::write> outTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    outTexture.write(float4(color.rgb, 1.0), gid);
}

//kernel void camera(texture2d<float, access::read> yTexture    [[texture(0)]],
//                   texture2d<float, access::read> cbcrTexture [[texture(1)]],
//                   texture2d<float, access::write> outTexture [[texture(2)]],
//                   uint2 gid [[thread_position_in_grid]])
//{
//    float3   colorOffset = float3(-(16.0/255.0), -0.5, -0.5);
//    float3x3 colorMatrix = float3x3(float3(1.164,  1.164, 1.164),
//                                    float3(0.000, -0.392, 2.017),
//                                    float3(1.596, -0.813, 0.000));
////    float3x3 colorMatrix = float3x3(float3(1.000,  1.000, 1.000),
////                                    float3(0.000, -0.187, 1.856),
////                                    float3(1.575, -0.468, 0.000));
//
//    float  y = yTexture.read(gid).r;
//    float2 cbcr = cbcrTexture.read(uint2(gid.x/2, gid.y/2)).rg;
//    float3 ycbcr = float3(y, cbcr);
//    float3 rbg = colorMatrix * (ycbcr + colorOffset);
//    float3 rgb = float3(rbg.b, rbg.g, rbg.r);
//
//    outTexture.write(float4(float3(rgb), 1.0), gid);
//}