//
//  Kuwahara.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct KuwaharaUniforms {
    float radius;
};

kernel void kuwahara(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant KuwaharaUniforms &uniforms        [[ buffer(0) ]],
                     uint2 gid [[thread_position_in_grid]])
{
//    float2 size = float2(1.0 / inTexture.get_width(), 1.0 / inTexture.get_height());
    
    float n = float((uniforms.radius + 1) * (uniforms.radius + 1));
    int i; int j;
    float3 m0 = float3(0.0); float3 m1 = float3(0.0); float3 m2 = float3(0.0); float3 m3 = float3(0.0);
    float3 s0 = float3(0.0); float3 s1 = float3(0.0); float3 s2 = float3(0.0); float3 s3 = float3(0.0);
    float3 c;
    float radius = uniforms.radius;
    
    for (j = -radius; j <= 0; ++j)  {
        for (i = -radius; i <= 0; ++i)  {
            c = inTexture.read(gid + uint2(i, j)).rgb;
            m0 += c;
            s0 += c * c;
        }
    }
    
    for (j = -radius; j <= 0; ++j)  {
        for (i = 0; i <= radius; ++i)  {
            c = inTexture.read(gid + uint2(i, j)).rgb;
            m1 += c;
            s1 += c * c;
        }
    }
    
    for (j = 0; j <= radius; ++j)  {
        for (i = 0; i <= radius; ++i)  {
            c = inTexture.read(gid + uint2(i, j)).rgb;
            m2 += c;
            s2 += c * c;
        }
    }
    
    for (j = 0; j <= radius; ++j)  {
        for (i = -radius; i <= 0; ++i)  {
            c = inTexture.read(gid + uint2(i, j)).rgb;
            m3 += c;
            s3 += c * c;
        }
    }
    
    float min_sigma2 = 1e+2;
    m0 /= n;
    s0 = abs(s0 / n - m0 * m0);
    
    float sigma2 = s0.r + s0.g + s0.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        outTexture.write(float4(m0, 1.0), gid);
    }
    
    m1 /= n;
    s1 = abs(s1 / n - m1 * m1);
    
    sigma2 = s1.r + s1.g + s1.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        outTexture.write(float4(m1, 1.0), gid);
    }
    
    m2 /= n;
    s2 = abs(s2 / n - m2 * m2);
    
    sigma2 = s2.r + s2.g + s2.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        outTexture.write(float4(m2, 1.0), gid);
    }
    
    m3 /= n;
    s3 = abs(s3 / n - m3 * m3);
    
    sigma2 = s3.r + s3.g + s3.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        outTexture.write(float4(m3, 1.0), gid);
    }
}