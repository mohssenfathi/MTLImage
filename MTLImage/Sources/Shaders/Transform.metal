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

};

kernel void transform(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                      texture2d<float, access::write> outTexture [[ texture(1)]],
                      constant TransformUniforms &uniforms       [[ buffer(0) ]],
                      device float *transformBuffer              [[ buffer(1) ]],
                      uint2 gid [[thread_position_in_grid]])
{
//    float4x4 transformMatrix = float4x4(float4(transformBuffer[0], transformBuffer[1], transformBuffer[2], transformBuffer[3]),
//                                        float4(transformBuffer[4], transformBuffer[5], transformBuffer[6], transformBuffer[7]),
//                                        float4(transformBuffer[8], transformBuffer[9], transformBuffer[10], transformBuffer[11]),
//                                        float4(transformBuffer[12], transformBuffer[13], transformBuffer[14], transformBuffer[15]));
//
//    uint4 i = uint4(transformMatrix * float4(float2(gid), 1, 1));
//    float4 color = inTexture.read(i.xy);

    
    float3x3 transformMatrix = float3x3(float3(transformBuffer[0], transformBuffer[1], 0.0),
                                        float3(transformBuffer[2], transformBuffer[3], 0.0),
                                        float3(transformBuffer[4], transformBuffer[5], 1.0));

    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 uv = float2(gid) / size;
    
    // Set anchor point to center of texture
    uv -= float2(0.5);
    
    float2 i = (transformMatrix * float3(uv, 1)).xy;
    
    // Undo set anchor point
    i += float2(0.5);

    // Adjust size for rotation. Doesn't work
    float angle = atan2(transformBuffer[1], transformBuffer[0]);
    size = float2(size.x * cos(angle) + size.y * sin(angle),
                  size.x * sin(angle) + size.y * cos(angle));
    
    float4 color = inTexture.read(uint2(i * size));
    
    outTexture.write(color, gid);
}
