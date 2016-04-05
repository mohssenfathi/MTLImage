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

struct VertexInOut {
    float4 pos      [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut crossHatchVertex(constant float4             *position  [[ buffer(0) ]],
                                    constant packed_float2      *texCoords [[ buffer(1) ]],
                                    constant CrossHatchUniforms &uniforms  [[ buffer(2) ]],
                                    uint                        vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 crossHatchFragment(VertexInOut     input                        [[ stage_in ]],
                                  texture2d<half> tex2D                        [[ texture(0) ]],
                                  constant        CrossHatchUniforms &uniforms [[ buffer(1) ]])
{
    
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    float luminance = dot(color.rgb, half3(0.2125, 0.7154, 0.0721));
    
    float crossHatchSpacing = uniforms.crossHatchSpacing;
    float lineWidth = uniforms.lineWidth;
    
    half4 colorToDisplay = half4(1.0, 1.0, 1.0, 1.0);
    float x = input.texCoord.x;
    float y = input.texCoord.y;
    
    if (luminance < 1.00) {
        if (fmod(x + y, crossHatchSpacing) <= lineWidth) {
            colorToDisplay = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.75) {
        if (fmod(x - y, crossHatchSpacing) <= lineWidth) {
            colorToDisplay = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.50) {
        if (fmod(x + y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
            colorToDisplay = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.3) {
        if (fmod(x - y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth) {
            colorToDisplay = float4(0.0, 0.0, 0.0, 1.0);
        }
    }
    
    return colorToDisplay;
}
