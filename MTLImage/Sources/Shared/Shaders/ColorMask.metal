//
//  ColorMask.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 9/5/17.
//

#include <metal_stdlib>
//#include <metal_geometric>
using namespace metal;

struct ColorMaskUniforms {
    float r;
    float g;
    float b;
    
    float hThreshold;
    float sThreshold;
    float vThreshold;
    
    float useMask;
};

float3 rgb2hsv(float3 c);
float3 hsv2rgb(float3 c);


//varying float2 textureCoordinate;
//
//uniform sampler2D inputImageTexture;
//uniform float3 inputColor;
//uniform float hthreshold;
//uniform float sthreshold;
//uniform float vthreshold;
//uniform float usemask;

kernel void colorMask(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                      texture2d<float, access::write> outTexture [[ texture(1) ]],
                      constant ColorMaskUniforms &uniforms       [[ buffer(0)  ]],
                      uint2 gid                                  [[thread_position_in_grid]])
{

//    float d;
    float4 pc = inTexture.read(gid);
    float3 inputColor = float3(uniforms.r, uniforms.g, uniforms.b);
    
    // get hsv versions of current pixel and input
    float3 p = rgb2hsv(pc.rgb);
    float3 i = rgb2hsv(inputColor);
    
    
    float3 dist = distance(p, i);
    
    // grab which of the 3 channels fall within the needed range  0=match  1=not_matched
    float hmatch = step(uniforms.hThreshold, dist.r);
    float smatch = step(uniforms.sThreshold, dist.g);
    float vmatch = step(uniforms.vThreshold, dist.g);

    // all must match (be 0) for the pixel to match
    float matched = max(max(hmatch, smatch), vmatch);

    // invert for sanity
    matched = abs(matched - 1.0);

//    float matchedMult = abs(uniforms.useMask - 1.0);

    // this colors the matched pixels to 1.0 (white)
    float3 out1 = clamp(pc.rgb + matched, float3(0.0), float3(1.0));

    // this colors the matched pixels to 1.0 (white)
    float3 out2 = clamp(out1.rgb - (uniforms.useMask - matched), float3(0.0), float3(1.0));

    outTexture.write(float4(out2, pc.a), gid);
    
}


//float3 rgb2hsv(float3 c) {
//    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
//    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
//    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
//
//    float d = q.x - min(q.w, q.y);
//    float e = 0.0000000001; // 1.0e-10;
//    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
//}
//
//float3 hsv2rgb(float3 c) {
//    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
//    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
//}

