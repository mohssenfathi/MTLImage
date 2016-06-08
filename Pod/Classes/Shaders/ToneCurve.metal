//
//  ToneCurve.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ToneCurveUniforms {
    
};

kernel void toneCurve(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                      texture2d<float, access::write> outTexture [[ texture(1)]],
                      constant ToneCurveUniforms &uniforms       [[ buffer(0) ]],
                      device float *toneCurveBuffer              [[ buffer(1) ]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
 
    float redCurveValue   = float(toneCurveBuffer[int(color.r * 255) * 3 + 0])/255.0;
    float greenCurveValue = float(toneCurveBuffer[int(color.g * 255) * 3 + 1])/255.0;
    float blueCurveValue  = float(toneCurveBuffer[int(color.b * 255) * 3 + 2])/255.0;

    outTexture.write(float4(redCurveValue, greenCurveValue, blueCurveValue, color.a), gid);
}