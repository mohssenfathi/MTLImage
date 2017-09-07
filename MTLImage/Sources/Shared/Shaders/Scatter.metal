//
//  Scatter.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ScatterUniforms {
    float radius;
};

//constant float3 lum = float3(0.2125, 0.7154, 0.0721);

kernel void scatter(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                    texture2d<float, access::write> outTexture [[ texture(1)]],
                    texture2d<float, access::read>  noise      [[ texture(2)]],
                    constant ScatterUniforms &uniforms         [[ buffer(0) ]],
                    uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
// noise.read(uint2(gid.x * uniforms.radius * 2, gid.y * uniforms.radius * 2)).xy
//    float l = dot(noise.read(gid).rgb, float3(0.2125, 0.7154, 0.0721));
    
    float3 noiseColor = noise.read(gid).rgb;
    float l = (1.5 - (noiseColor.r + noiseColor.g + noiseColor.b)) * uniforms.radius;
    float2 workingSpaceCoord = float2(gid) - l * 2;
    color = inTexture.read(uint2(workingSpaceCoord));
    
//    float2 imageSpaceCoord = samplerTransform(image, workingSpaceCoord);
//    return sample(image, imageSpaceCoord);
    
    outTexture.write(color, gid);
}