//
//  YCbCrToRGB.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 2/16/18.
//

#include <metal_stdlib>

using namespace metal;

struct YCbCrToRGBUniforms {
    float4x4 transformMatrix;
};

kernel void YCbCrToRGB(texture2d<float, access::write> outTexture [[ texture(0) ]],
                       texture2d<float, access::sample> Y [[ texture(1) ]],
                       texture2d<float, access::sample> CbCr [[ texture(2) ]],
                       constant YCbCrToRGBUniforms &uniforms    [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]]) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
                                                  float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                                  float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                                  float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                                  float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
                                                  );
    float2 size = float2(Y.get_width(), Y.get_height());
    float2 normal = float2(gid)/size;
    uint2 gid_CbCr = uint2(normal * float2(CbCr.get_width(), CbCr.get_height()));
    
    float y = Y.read(gid).r;
    float2 cbcr = CbCr.read(gid_CbCr).rg;
    float4 ycbcr = float4(y, cbcr, 1.0);
    
//    outTexture.write(uniforms.transformMatrix * ycbcr, gid);
    outTexture.write(ycbcrToRGBTransform * ycbcr, gid);
}
