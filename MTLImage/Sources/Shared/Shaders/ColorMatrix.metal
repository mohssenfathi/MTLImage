//
//  ColorMatrix.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/20/18.
//

#include <metal_stdlib>
using namespace metal;

struct ColorMatrixUniforms {
    float4 red;
    float4 green;
    float4 blue;
    float4 alpha;
    float4 bias;
};

kernel void colorMatrix(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        constant ColorMatrixUniforms &uniforms     [[ buffer(0) ]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    float4x4 mat = float4x4(uniforms.red, uniforms.green, uniforms.blue, uniforms.alpha);
    color = mat * color + uniforms.bias;
    
    outTexture.write(color, gid);
}
