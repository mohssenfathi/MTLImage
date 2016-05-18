//
//  crop.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/14/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float convertValue(float value, float oldMin, float oldMax, float newMin, float newMax);

struct CropUniforms {
    float x;
    float y;
    float width;
    float height;
    int fit;
};

kernel void crop(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                 texture2d<float, access::write> outTexture [[ texture(1)]],
                 constant CropUniforms &uniforms            [[ buffer(0) ]],
                 uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float ratio = size.x / size.y;
    float2 uv = float2(gid)/size;
    
    if (uniforms.fit) {
        
        float newRatio = (uniforms.width * size.x) / (uniforms.height * size.y);
        float4 newFrame;
        
//        [ x, y, z, w ]
        if (newRatio > ratio) {  // fit width
            newFrame.x = 0;
            newFrame.z = size.x;
            newFrame.w = size.x / newRatio;
            newFrame.y = (size.y - newFrame.w) / 2.0;
        }
        else {  // fit height
            newFrame.y = 0;
            newFrame.w = size.y;
            newFrame.z = size.y * newRatio;
            newFrame.x = (size.x - newFrame.z) / 2.0;
        }

        if (gid.x < newFrame.x || gid.y < newFrame.y || gid.x > newFrame.x + newFrame.z || gid.y > newFrame.y + newFrame.w) {
            color = float4(0);
        }
        else {            
            float vx = convertValue(uv.x, newFrame.x/size.x, (newFrame.x + newFrame.z)/size.x, 0, 1);
            float vy = convertValue(uv.y, newFrame.y/size.y, (newFrame.y + newFrame.w)/size.y, 0, 1);
            float x  = (uniforms.x + vx * uniforms.width ) * size.x;
            float y  = (uniforms.y + vy * uniforms.height) * size.y;
            
            color = inTexture.read(uint2(x, y));
        }
    }
    else {
        if (uv.x < uniforms.x || uv.y < uniforms.y || uv.x > uniforms.x + uniforms.width || uv.y > uniforms.y + uniforms.height) {
            color = float4(0);
        }
    }
    
    outTexture.write(color, gid);
}