//
//  Saturation.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
using namespace metal;

struct GaussianBlurUniforms {
    float blurRadius;
    float sigma;
    
    float texelWidthOffset;
    float texelHeightOffset;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
    
    float2 centerTextureCoordinate;
    float2 oneStepLeftTextureCoordinate;
    float2 twoStepsLeftTextureCoordinate;
    float2 oneStepRightTextureCoordinate;
    float2 twoStepsRightTextureCoordinate;
};

vertex VertexInOut gaussianBlurVertex(constant float4         *position   [[ buffer(0) ]],
                                      constant packed_float2  *texCoords  [[ buffer(1) ]],
//                                      constant float4x4       *pMVP       [[ buffer(2) ]],
                                      constant GaussianBlurUniforms &uniforms [[ buffer(2) ]],
                                      uint                     vid        [[ vertex_id ]])
{
    VertexInOut output;

    output.pos      = position[vid];
    output.texCoord = texCoords[vid];

//    float2 inputTextureCoordinate = texCoords[vid];
//    float texelWidthOffset = 0.001; //uniforms.texelWidthOffset;
//    float texelHeightOffset = 0.001; //uniforms.texelHeightOffset;
//    
//    float2 firstOffset  = float2(1.3846153846 * texelWidthOffset, 1.3846153846 * texelHeightOffset);
//    float2 secondOffset = float2(3.2307692308 * texelWidthOffset, 3.2307692308 * texelHeightOffset);
//    
//    output.centerTextureCoordinate        = inputTextureCoordinate;
//    output.oneStepLeftTextureCoordinate   = inputTextureCoordinate - firstOffset;
//    output.twoStepsLeftTextureCoordinate  = inputTextureCoordinate - secondOffset;
//    output.oneStepRightTextureCoordinate  = inputTextureCoordinate + firstOffset;
//    output.twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;

    return output;
}

fragment half4 gaussianBlurFragment(VertexInOut        input    [[ stage_in ]],
                                    texture2d<half>    tex2D    [[ texture(0) ]],
                                    texture2d<float>   weights  [[ texture(1) ]],
                                    constant GaussianBlurUniforms &uniforms [[ buffer(1) ]])
{
    constexpr sampler quad_sampler;
    
////    half4 color = tex2D.sample(quad_sampler, input.texCoord);
////    return color;
//    
//    half3 fragmentColor;
////    fragmentColor  = tex2D.sample(quad_sampler, input.texCoord                      ).rgb * 0.2270270270;
////    fragmentColor += tex2D.sample(quad_sampler, input.oneStepLeftTextureCoordinate  ).rgb * 0.3162162162;
////    fragmentColor += tex2D.sample(quad_sampler, input.oneStepRightTextureCoordinate ).rgb * 0.3162162162;
////    fragmentColor += tex2D.sample(quad_sampler, input.twoStepsLeftTextureCoordinate ).rgb * 0.0702702703;
////    fragmentColor += tex2D.sample(quad_sampler, input.twoStepsRightTextureCoordinate).rgb *
//    fragmentColor  = tex2D.sample(quad_sampler, input.texCoord                      ).rgb * half3(weights.sample(quad_sampler, input.texCoord).rrr);
//    fragmentColor += tex2D.sample(quad_sampler, input.oneStepLeftTextureCoordinate  ).rgb * half3(weights.sample(quad_sampler, input.oneStepLeftTextureCoordinate).rrr);
//    fragmentColor += tex2D.sample(quad_sampler, input.oneStepRightTextureCoordinate ).rgb * half3(weights.sample(quad_sampler, input.oneStepRightTextureCoordinate).rrr);
//    fragmentColor += tex2D.sample(quad_sampler, input.twoStepsLeftTextureCoordinate ).rgb * half3(weights.sample(quad_sampler, input.twoStepsLeftTextureCoordinate).rrr);
//    fragmentColor += tex2D.sample(quad_sampler, input.twoStepsRightTextureCoordinate).rgb * half3(weights.sample(quad_sampler, input.twoStepsRightTextureCoordinate).rrr);
//
////    half4 color = half4(1.0 / uniforms.blurRadius, 0, 0, 1);
////    half4(input.texCoord.x - input.oneStepLeftTextureCoordinate.x * 10, 0, 0, 1);
//
//    return half4(fragmentColor, 1.0);
    
    
    int size = weights.get_width();
    int radius = size / 2;
    
    half4 accumColor(0, 0, 0, 0);
    for (int j = 0; j < size; ++j) {
        for (int i = 0; i < size; ++i) {
            float2 kernelIndex = float2(i, j);
            float2 textureIndex = float2(input.texCoord.x + (i - radius), input.texCoord.y + (j - radius));
            half4 color = tex2D.sample(quad_sampler, textureIndex).rgba;
            float4 weight = weights.sample(quad_sampler, kernelIndex).rrrr;
            accumColor += half4(weight) * color;
        }
    }
    
    return half4(accumColor.rgb, 1);
    
    
}
