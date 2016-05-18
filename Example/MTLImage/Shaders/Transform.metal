//
//  Transform.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/17/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct TransformUniforms {
//    float4x4 matrix;
//    float4x4 orthoMatrix;
};

kernel void transform(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                      texture2d<float, access::write> outTexture [[ texture(1)]],
                      constant TransformUniforms &uniforms       [[ buffer(0) ]],
                      device float *transformBuffer              [[ buffer(1) ]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    float4x4 transformMatrix = float4x4(float4(transformBuffer[0], transformBuffer[1], transformBuffer[2], transformBuffer[3]),
                                        float4(transformBuffer[4], transformBuffer[5], transformBuffer[6], transformBuffer[7]),
                                        float4(transformBuffer[8], transformBuffer[9], transformBuffer[10], transformBuffer[11]),
                                        float4(transformBuffer[12], transformBuffer[13], transformBuffer[14], transformBuffer[15]));
    
    uint4 i = uint4(transformMatrix * float4(float2(gid), 1, 1));
    
    outTexture.write(color, i.xy);
}