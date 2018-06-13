//
//  Normalize.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/30/18.
//

#include <metal_stdlib>
using namespace metal;

struct NormalizeUniforms {
    float4 fromMin;
    float4 fromMax;
};

kernel void normalize(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                      texture2d<float, access::write> outTexture [[ texture(1)]],
                      constant NormalizeUniforms &uniforms       [[ buffer(0) ]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    color = color - uniforms.fromMin / uniforms.fromMax - uniforms.fromMin;
    outTexture.write(color, gid);
}
