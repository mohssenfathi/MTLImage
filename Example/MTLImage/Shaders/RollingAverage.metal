//
//  Buffer.metal
//  MTLImage_Example
//
//  Created by Mohssen Fathi on 6/15/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RollingAverageUniforms {
    float bufferLength;
    float currentBufferCount;
};

kernel void rollingAverage(texture2d<float, access::read>  inTexture     [[texture(0)]],
                           texture2d<float, access::write> outTexture    [[texture(1)]],
                           texture2d<float, access::read>  addTexture    [[texture(2)]],
                           texture2d<float, access::read>  subTexture    [[texture(3)]],
                           constant RollingAverageUniforms &uniforms [[ buffer(0) ]],
                           uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    
    color += addTexture.read(gid) / uniforms.bufferLength;
    
    if (uniforms.currentBufferCount >= uniforms.bufferLength) {
        color -= subTexture.read(gid) / uniforms.bufferLength;
    }
    
    outTexture.write(color, gid);
}

