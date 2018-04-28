//
//  ColorClamp.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

#include <metal_stdlib>
using namespace metal;

struct ColorClampUniforms {
    float4 min, max;
};

kernel void colorClamp(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                       texture2d<float, access::write> outTexture [[ texture(1) ]],
                       constant ColorClampUniforms &uniforms      [[ buffer(0)  ]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    color = clamp(color, uniforms.min, uniforms.max);
    outTexture.write(color, gid);
}
