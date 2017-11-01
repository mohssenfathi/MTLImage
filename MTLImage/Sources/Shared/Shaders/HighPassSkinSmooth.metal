//
//  HighPassSkinSmooth.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 9/14/17.
//

#include <metal_stdlib>
using namespace metal;


kernel void highPassSkinSmooth(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                               texture2d<float, access::write> outTexture [[ texture(1) ]],
                               texture2d<float, access::read>  secondaryTexture [[ texture(2) ]],
                               uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    float hardLightColor = color.b;
    
    for (int i = 0; i < 3; ++i) {
        if (hardLightColor < 0.5) {
            hardLightColor = hardLightColor  * hardLightColor * 2.0;
        } else {
            hardLightColor = 1.0 - (1.0 - hardLightColor) * (1.0 - hardLightColor) * 2.0;
        }
    }
    
    float k = 255.0 / (164.0 - 75.0);
    
    hardLightColor = (hardLightColor - 75.0 / 255.0) * k;
    
    outTexture.write(float4(float3(hardLightColor), color.a), gid);
}
