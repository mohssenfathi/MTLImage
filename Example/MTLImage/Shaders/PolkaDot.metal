//
//  Saturation.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PolkaDotUniforms {
    float dotRadius;
    float aspectRatio;
    float fractionalWidthOfPixel;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut polkaDotVertex(constant float4           *position  [[ buffer(0) ]],
                                  constant packed_float2    *texCoords [[ buffer(1) ]],
                                  constant PolkaDotUniforms &uniforms  [[ buffer(2) ]],
                                  uint                      vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

fragment half4 polkaDotFragment(VertexInOut     input  [[ stage_in ]],
                                texture2d<half> tex2D  [[ texture(0) ]],
                                constant PolkaDotUniforms &uniforms [[buffer(1)]])
{
    
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    
    float2 sampleDivisor = float2(uniforms.fractionalWidthOfPixel, uniforms.fractionalWidthOfPixel / uniforms.aspectRatio);
    float2 samplePos = input.texCoord - fmod(input.texCoord, sampleDivisor) + 0.5 * sampleDivisor;
    
    float2 textureCoordinateToUse = float2(input.texCoord.x, (input.texCoord.y * uniforms.aspectRatio + 0.5 - 0.5 * uniforms.aspectRatio));
    float2 adjustedSamplePos = float2(samplePos.x, (samplePos.y * uniforms.aspectRatio + 0.5 - 0.5 * uniforms.aspectRatio));
    float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    float checkForPresenceWithinDot = step(distanceFromSamplePoint, (uniforms.fractionalWidthOfPixel * 0.5) * uniforms.dotRadius);
    
    
    return half4(color.rgb * checkForPresenceWithinDot, color.a);
}
