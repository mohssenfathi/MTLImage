//
//  Blend.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlendUniforms {
    float mix;
    int blendMode;
};

kernel void blend(texture2d<float, access::read>  inTexture        [[ texture(0) ]],
                  texture2d<float, access::write> outTexture       [[ texture(1) ]],
                  texture2d<float, access::read>  secondaryTexture [[ texture(2) ]],
                  constant BlendUniforms &uniforms                 [[ buffer(0) ]],
                  uint2 gid [[thread_position_in_grid]])
{
    float4 color1 = inTexture.read(gid);
    float4 color2 = secondaryTexture.read(gid);
    float4 color;
    
    float a = color1.a + color2.a * (1.0 - color1.a);
    float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output
    
    color.r = (color1.r * color1.a + color2.r * color2.a * (1.0 - color1.a))/alphaDivisor;
    color.g = (color1.g * color1.a + color2.g * color2.a * (1.0 - color1.a))/alphaDivisor;
    color.b = (color1.b * color1.a + color2.b * color2.a * (1.0 - color1.a))/alphaDivisor;
    color.a = a;
    
    outTexture.write(color, gid);
}