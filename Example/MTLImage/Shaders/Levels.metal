//
//  Levels.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define GammaCorrection(color, gamma)  pow(color, 1.0 / gamma)

#define LevelsControlInputRange(color, minInput, maxInput)	min(max(color - minInput, float3(0.0)) / (maxInput - minInput), float3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)	GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 	mix(minOutput, maxOutput, color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

struct LevelsUniforms {
    float min;
    float mid;
    float max;
    float minOut;
    float maxOut;
};

kernel void levels(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                   texture2d<float, access::write> outTexture [[ texture(1) ]],
                   constant LevelsUniforms &uniforms        [[ buffer(0) ]],
                   uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    outTexture.write(float4(LevelsControl(color.rgb, uniforms.min,
                                          uniforms.mid, uniforms.max,
                                          uniforms.minOut, uniforms.maxOut), color.a), gid);
}