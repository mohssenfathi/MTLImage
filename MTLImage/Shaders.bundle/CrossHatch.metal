//
//  Saturation.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct CrossHatchUniforms {
    float crossHatchSpacing;
    float lineWidth;
};

kernel void crossHatch(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                       texture2d<float, access::write> outTexture [[ texture(1) ]],
                       constant CrossHatchUniforms &uniforms      [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float luminance = dot(color.rgb, float3(0.2125, 0.7154, 0.0721));
    
    float crossHatchSpacing = uniforms.crossHatchSpacing;
    float lineWidth = uniforms.lineWidth;
    
    float4 outColor = float4(1.0, 1.0, 1.0, 1.0);

    if (luminance < 1.00) {
        if (fmod(gid.x + gid.y, crossHatchSpacing) <= lineWidth) {
            outColor = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.75) {
        if (fmod(gid.x - gid.y, crossHatchSpacing) <= lineWidth) {
            outColor = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.50) {
        if (fmod(gid.x + gid.y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
            outColor = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.3) {
        if (fmod(gid.x - gid.y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
            outColor = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    
//    float2 size = float2(inTexture.get_width(), inTexture.get_height());
//    float x = gid.x/size.x;
//    float y = gid.y/size.y;
    
//    if (luminance < 1.00) {
//        if (fmod(x + y, crossHatchSpacing) <= lineWidth) {
//            outColor = float4(0.0, 0.0, 0.0, 1.0);
//        }
//    }
//    if (luminance < 0.75) {
//        if (fmod(x - y, crossHatchSpacing) <= lineWidth) {
//            outColor = float4(0.0, 0.0, 0.0, 1.0);
//        }
//    }
//    if (luminance < 0.50) {
//        if (fmod(x + y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
//            outColor = float4(0.0, 0.0, 0.0, 1.0);
//        }
//    }
//    if (luminance < 0.3) {
//        if (fmod(x - y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
//            outColor = float4(0.0, 0.0, 0.0, 1.0);
//        }
//    }
    
    outTexture.write(outColor, gid);
}
