//
//  ColorMask.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 8/29/17.
//

#include <metal_stdlib>
using namespace metal;

struct ColorMaskUniforms {
    float r;
    float g;
    float b;
    float a;
    float threshold;
};

float3 normalizeColor(float3 color);

kernel void colorMask(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                      texture2d<float, access::write> outTexture [[ texture(1) ]],
                      constant ColorMaskUniforms &uniforms  [[ buffer(0)  ]],
                      uint2 gid                                  [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float4 match = float4(uniforms.r, uniforms.g, uniforms.b, uniforms.a);
    
    // No color set
    if (uniforms.a < 1.0) {
        outTexture.write(color, gid);
        return;
    }
    
    float d = distance(normalizeColor(color.rgb), normalizeColor(match.rgb));
    if (d > uniforms.threshold) {
        outTexture.write(float4(1, 1, 1, 0), gid);
        return;
    }
    
    outTexture.write(color, gid);
}

float3 normalizeColor(float3 color) {
    return color / max(dot(color, float3(1.0/3.0)), 0.3);
}
