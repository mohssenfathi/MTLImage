//
//  MaskBlend.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/22/18.
//

#include <metal_stdlib>
using namespace metal;

struct MaskBlendUniforms {
    bool showMask;
};

kernel void maskBlend(texture2d<float, access::read>  inTexture       [[ texture(0) ]],
                      texture2d<float, access::write> outTexture      [[ texture(1) ]],
                      texture2d<float, access::read> secondaryTexture [[ texture(2) ]],
                      texture2d<float, access::read> maskTexture      [[ texture(3) ]],
                      constant MaskBlendUniforms &uniforms            [[ buffer(0) ]],
                      uint2 gid [[thread_position_in_grid]])
{
    
    if (uniforms.showMask) {
        outTexture.write(maskTexture.read(gid), gid);
        return;
    }
    
    float4 color0 = inTexture.read(gid);
    float4 color1 = secondaryTexture.read(gid);
    float4 mask = maskTexture.read(gid);
    
    float3 color = mix(color0.rgb, color1.rgb, mask.r);
    
    outTexture.write(float4(color, 1.0), gid);
}
