//
//  ColorGenerator.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/18.
//

#include <metal_stdlib>
using namespace metal;

struct ColorGeneratorUniforms {
    float4 color;
};

kernel void colorGenerator(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                           texture2d<float, access::write> outTexture [[ texture(1) ]],
                           constant ColorGeneratorUniforms &uniforms        [[ buffer(0) ]],
                           uint2 gid [[thread_position_in_grid]])
{
    outTexture.write(uniforms.color, gid);
}
