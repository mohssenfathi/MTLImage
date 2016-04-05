//
//  Sharpen.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SharpenUniforms {
    float sharpness;
    float imageWidthFactor;
    float imageHeightFactor;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
    
    float2 leftTextureCoordinate;
    float2 rightTextureCoordinate;
    float2 topTextureCoordinate;
    float2 bottomTextureCoordinate;
    
    float centerMultiplier;
    float edgeMultiplier;
};

vertex VertexInOut sharpenVertex(constant float4           *position  [[ buffer(0) ]],
                                  constant packed_float2     *texCoords [[ buffer(1) ]],
                                  constant SharpenUniforms &uniforms  [[ buffer(2) ]],
                                  uint                       vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    float2 widthStep  = float2(uniforms.imageWidthFactor, 0.0);
    float2 heightStep = float2(0.0, uniforms.imageHeightFactor);
    
    
    output.leftTextureCoordinate = texCoords[vid] - widthStep;
    output.rightTextureCoordinate = texCoords[vid] + widthStep;
    output.topTextureCoordinate = texCoords[vid] + heightStep;
    output.bottomTextureCoordinate = texCoords[vid] - heightStep;
    
    output.centerMultiplier = 1.0 + 4.0 * uniforms.sharpness;
    output.edgeMultiplier = uniforms.sharpness;
    
    return output;
}

fragment half4 sharpenFragment(VertexInOut    input  [[ stage_in ]],
                                texture2d<half> tex2D  [[ texture(0) ]],
                                constant SharpenUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    
    half3 textureColor = tex2D.sample(quad_sampler, input.texCoord).rgb;
    half3 leftTextureColor = tex2D.sample(quad_sampler, input.leftTextureCoordinate).rgb;
    half3 rightTextureColor = tex2D.sample(quad_sampler, input.rightTextureCoordinate).rgb;
    half3 topTextureColor = tex2D.sample(quad_sampler, input.topTextureCoordinate).rgb;
    half3 bottomTextureColor = tex2D.sample(quad_sampler, input.bottomTextureCoordinate).rgb;
        
    return half4((textureColor * input.centerMultiplier - (leftTextureColor * input.edgeMultiplier + rightTextureColor * input.edgeMultiplier + topTextureColor * input.edgeMultiplier + bottomTextureColor * input.edgeMultiplier)), tex2D.sample(quad_sampler, input.bottomTextureCoordinate).a);
}


