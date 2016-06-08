//
//  HighlightShadow.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/29/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant float3 luminanceWeighting = float3(0.3, 0.3, 0.3);

struct HighlightShadowUniforms {
    float highlights;
    float shadows;
};

kernel void highlightShadow(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                            texture2d<float, access::write> outTexture [[ texture(1)]],
                            constant HighlightShadowUniforms &uniforms [[ buffer(0) ]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    float luminance = dot(color.rgb, luminanceWeighting);
    
    float shadow = clamp((pow(luminance, 1.0/(uniforms.shadows + 1.0)) + (-0.76) * pow(luminance, 2.0/(uniforms.shadows+1.0))) - luminance, 0.0, 1.0);
    float highlight = clamp((1.0 - (pow(1.0 - luminance, 1.0/(2.0 - uniforms.highlights)) + (-0.8)*pow(1.0 - luminance, 2.0/(2.0 - uniforms.highlights)))) - luminance, -1.0, 0.0);
    color.rgb = float3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((color.rgb - float3(0.0, 0.0, 0.0))/(luminance - 0.0));
    
    outTexture.write(color, gid);
}