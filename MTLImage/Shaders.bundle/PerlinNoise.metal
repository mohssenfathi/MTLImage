//
//  PerlinNoise.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PerlinNoiseUniforms {
    float scale;
};

float4 mod289(float4 x);
float4 permute(float4 x);
float4 taylorInvSqrt(float4 r);
float2 fade(float2 t);
float cnoise(float2 P);

float4 mod289(float4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float2 fade(float2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// Classic Perlin noise
float cnoise(float2 P) {
    float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
    float4 Pf = fract(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
    Pi = mod289(Pi); // To avoid truncation effects in permutation
    float4 ix = Pi.xzxz;
    float4 iy = Pi.yyww;
    float4 fx = Pf.xzxz;
    float4 fy = Pf.yyww;
    
    float4 i = permute(permute(ix) + iy);
    
    float4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
    float4 gy = abs(gx) - 0.5 ;
    float4 tx = floor(gx + 0.5);
    gx = gx - tx;
    
    float2 g00 = float2(gx.x,gy.x);
    float2 g10 = float2(gx.y,gy.y);
    float2 g01 = float2(gx.z,gy.z);
    float2 g11 = float2(gx.w,gy.w);
    
    float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    
    float n00 = dot(g00, float2(fx.x, fy.x));
    float n10 = dot(g10, float2(fx.y, fy.y));
    float n01 = dot(g01, float2(fx.z, fy.z));
    float n11 = dot(g11, float2(fx.w, fy.w));
    
    float2 fade_xy = fade(Pf.xy);
    float2 n_x = mix(float2(n00, n01), float2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

kernel void perlinNoise(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        constant PerlinNoiseUniforms &uniforms     [[ buffer(0)  ]],
                        uint2 gid                                  [[thread_position_in_grid]])
{
//    float4 color = inTexture.read(gid);
    
    float n1 = (cnoise(float2(gid) * uniforms.scale) + 1.0) / 2.0;
    
    float4 colorStart  = float4(1, 1, 1, 1);
    float4 colorFinish = float4(0, 0, 0, 1);
    float4 colorDiff = colorFinish - colorStart;
    float4 color = colorStart + colorDiff * n1;
    
    outTexture.write(color, gid);
}