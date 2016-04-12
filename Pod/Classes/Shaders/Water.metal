//
//  Water.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float col(float2 coordinate, float time, float speed, float frequency, float intensity);

struct WaterUniforms {
    float time;
    float speed;
    float frequency;
    float intensity;
    float emboss;
    float delta;
    float intence;
};

struct Constants {
    const int steps = 6;
    const float PI = 3.1415926535897932;
    
    const int angle = 9;
    const float speed_x = 0.3;
    const float speed_y = 0.3;
    
    const float reflectionCutOff = 0.012;
    const float reflectionIntence = 200000.;
};


float col(float2 coordinate, float time, float speed, float frequency, float intensity) {
    Constants c;
    
    float delta_theta = 2.0 *c.PI / float(c.angle);
    float col = 0.0;
    float theta = 0.0;
    for (int i = 0; i < c.steps; i++) {
        float2 adjc = coordinate;
        theta = delta_theta * float(i);
        adjc.x += cos(theta) * time * speed + time * c.speed_x;
        adjc.y -= sin(theta) * time * speed - time * c.speed_y;
        col = col + cos( (adjc.x * cos(theta) - adjc.y * sin(theta)) * frequency) * intensity;
    }
    
    return cos(col);
}

kernel void water(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                  texture2d<float, access::write> outTexture [[ texture(1) ]],
                  constant WaterUniforms &uniforms           [[ buffer(0) ]],
                  uint2 gid [[thread_position_in_grid]])
{
    Constants c;
    
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 textureCoordinate = float2(gid.x/size.x, gid.y/size.y);
    float2 p = textureCoordinate.xy;
    float2 c1 = p;
    float2 c2 = p;
    float cc1 = col(c1, uniforms.time, uniforms.speed, uniforms.frequency, uniforms.intensity);
    
    c2.x += textureCoordinate.x/uniforms.delta;
    float cc2 = col(c2, uniforms.time, uniforms.speed, uniforms.frequency, uniforms.intensity);
    float dx = uniforms.emboss * (cc1 - cc2)/uniforms.delta;
    
    c2.x = p.x;
    c2.y += textureCoordinate.y/uniforms.delta;
    cc2 = col(c2, uniforms.time, uniforms.speed, uniforms.frequency, uniforms.intensity);
    float dy = uniforms.emboss * (cc1-cc2)/uniforms.delta;
    
    c1.x += dx * 2.;
    //     c1.y = -(c1.y + dy * 2.);
    
    float alpha = 1.0 + dx * dy * uniforms.intence;
    
    float ddx = dx - c.reflectionCutOff;
    float ddy = dy - c.reflectionCutOff;
    if (ddx > 0. && ddy > 0.) {
        alpha = pow(alpha, ddx * ddy * c.reflectionIntence);
    }
    
    uint2 g = uint2(c1.x * size.x, c1.y * size.y);
    float4 color = inTexture.read(g);
    outTexture.write(color, gid);
}