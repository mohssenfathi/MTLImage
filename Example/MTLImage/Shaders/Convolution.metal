//
//  3x3Convolution.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ConvolutionUniforms {
    half3x3 convolutionMatrix;
    float texelWidth;
    float texelHeight;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
    
    float2 leftTextureCoordinate;
    float2 rightTextureCoordinate;
    float2 topTextureCoordinate;
    float2 topLeftTextureCoordinate;
    float2 topRightTextureCoordinate;
    float2 bottomTextureCoordinate;
    float2 bottomLeftTextureCoordinate;
    float2 bottomRightTextureCoordinate;
};

vertex VertexInOut convolutionVertex(constant float4              *position  [[ buffer(0) ]],
                                     constant packed_float2       *texCoords [[ buffer(1) ]],
                                     constant ConvolutionUniforms &uniforms  [[ buffer(2) ]],
                                     uint                         vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    float texelWidth = 0.01;
    float texelHeight = 0.01;
    
    float2 widthStep = float2(texelWidth, 0.0);
    float2 heightStep = float2(0.0, texelHeight);
    float2 widthHeightStep = float2(texelWidth, texelHeight);
    float2 widthNegativeHeightStep = float2(texelWidth, -texelHeight);
    
    output.leftTextureCoordinate = texCoords[vid] - widthStep;
    output.rightTextureCoordinate = texCoords[vid] + widthStep;
    
    output.topTextureCoordinate = texCoords[vid] - heightStep;
    output.topLeftTextureCoordinate = texCoords[vid] - widthHeightStep;
    output.topRightTextureCoordinate = texCoords[vid] + widthNegativeHeightStep;
    
    output.bottomTextureCoordinate = texCoords[vid] + heightStep;
    output.bottomLeftTextureCoordinate = texCoords[vid] - widthNegativeHeightStep;
    output.bottomRightTextureCoordinate = texCoords[vid] + widthHeightStep;
    
    return output;
}

fragment half4 convolutionFragment(VertexInOut    input  [[ stage_in ]],
                                  texture2d<half> tex2D  [[ texture(0) ]],
                                  constant ConvolutionUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    
    half3 bottomColor      = tex2D.sample(quad_sampler, input.bottomTextureCoordinate).rgb;
    half3 bottomLeftColor  = tex2D.sample(quad_sampler, input.bottomLeftTextureCoordinate).rgb;
    half3 bottomRightColor = tex2D.sample(quad_sampler, input.bottomRightTextureCoordinate).rgb;
    half4 centerColor      = tex2D.sample(quad_sampler, input.texCoord);
    half3 leftColor        = tex2D.sample(quad_sampler, input.leftTextureCoordinate).rgb;
    half3 rightColor       = tex2D.sample(quad_sampler, input.rightTextureCoordinate).rgb;
    half3 topColor         = tex2D.sample(quad_sampler, input.topTextureCoordinate).rgb;
    half3 topRightColor    = tex2D.sample(quad_sampler, input.topRightTextureCoordinate).rgb;
    half3 topLeftColor     = tex2D.sample(quad_sampler, input.topLeftTextureCoordinate).rgb;
    
    half3 resultColor = topLeftColor * uniforms.convolutionMatrix[0][0] + topColor * uniforms.convolutionMatrix[0][1] + topRightColor * uniforms.convolutionMatrix[0][2];
    resultColor += leftColor * uniforms.convolutionMatrix[1][0] + centerColor.rgb * uniforms.convolutionMatrix[1][1] + rightColor * uniforms.convolutionMatrix[1][2];
    resultColor += bottomLeftColor * uniforms.convolutionMatrix[2][0] + bottomColor * uniforms.convolutionMatrix[2][1] + bottomRightColor * uniforms.convolutionMatrix[2][2];
    
    return half4(resultColor, centerColor.a);
}