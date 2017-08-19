//
//  Smudge.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/26/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SmudgeUniforms {
    float radius;
    float x;
    float y;
    float dx;
    float dy;
    float force;
};

kernel void smudge(texture2d<float, access::read>  inTexture  [[texture(0)]],
                   texture2d<float, access::write> outTexture [[texture(1)]],
                   constant SmudgeUniforms &uniforms          [[ buffer(0) ]],
                   uint2 gid                                  [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    float2 newCoord = float2(gid);
    float dist = distance(float2(uniforms.x * inTexture.get_width(), uniforms.y * inTexture.get_height()), newCoord);
    
    if (dist < uniforms.radius) {
        float normalisedDistance = 1.0 - (dist / uniforms.radius);
        float smoothedDistance = smoothstep(0.0, 1.0, normalisedDistance);
    
        newCoord = float2(gid) + (float2(uniforms.dx, uniforms.dy) * uniforms.force) * smoothedDistance;
    }
    
    outTexture.write(color, uint2(newCoord));
}