//
//  Resize.metal
//  MTLImage_Example
//
//  Created by Mohssen Fathi on 6/12/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void resize(texture2d<float, access::read>  inputTexture   [[ texture(0) ]],
                   texture2d<float, access::write> outputTexture  [[ texture(1) ]],
                   uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 textureSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 outputSize   = float2(outputTexture.get_width(), outputTexture.get_height());
    float2 texCoord  = float2(gid) / textureSize;
    uint2  outputGid = uint2(texCoord * outputSize);
    
    outputTexture.write(inputTexture.read(gid), outputGid);
//    outputTexture.write(float4(1.0, 0.0, 0.0, 1.0), outputGid);
    
}

