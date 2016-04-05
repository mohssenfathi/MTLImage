//
//  Levels.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct LevelsUniforms {
    float min;
    float mid;
    float max;
    float minOut;
    float maxOut;
};

struct VertexInOut {
    float4 pos [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexInOut levelsVertex(constant float4           *position  [[ buffer(0) ]],
                                constant packed_float2     *texCoords [[ buffer(1) ]],
                                constant LevelsUniforms &uniforms  [[ buffer(2) ]],
                                uint                       vid        [[ vertex_id ]])
{
    VertexInOut output;
    
    output.pos = position[vid];
    output.texCoord = texCoords[vid];
    
    return output;
}

#define GammaCorrection(color, gamma)  pow(color, 1.0 / gamma)

#define LevelsControlInputRange(color, minInput, maxInput)	min(max(color - minInput, half3(0.0)) / (maxInput - minInput), half3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)	GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 	mix(minOutput, maxOutput, color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

//half LevelsControlInput(color, minInput, gamma, maxInput) {
//    GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
//}
//
//half4 LevelsControlOutputRange(half4 color, half minOutput, half maxOutput) {
//    return mix(minOutput, maxOutput, color);
//}
//
//half4 LevelsControl(half4 color, half minInput, half gamma, half maxInput, half minOutput, half maxOutput) {
//    return LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)
//}
//
////half LevelsControlInputRange(half4 color, half minInput, half maxInput) {
////    return min(max(color - minInput, half3(0.0)) / (maxInput - minInput), half3(1.0))
////}

fragment half4 levelsFragment(VertexInOut    input  [[ stage_in ]],
                              texture2d<half> tex2D  [[ texture(0) ]],
                              constant LevelsUniforms &uniforms [[buffer(1)]])
{
    constexpr sampler quad_sampler;
    half4 color = tex2D.sample(quad_sampler, input.texCoord);
    return half4(LevelsControl(color.rgb, uniforms.min, uniforms.mid, uniforms.max, uniforms.minOut, uniforms.maxOut), color.a);
}