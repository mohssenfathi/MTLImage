//
//  Voronoi.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 9/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//
//  From: https://www.shadertoy.com/view/ldl3W8#


//
// So sloooooooooooooooooooow
//

#include <metal_stdlib>
using namespace metal;

struct VoronoiUniforms {
    float time;
    float size;
    float animate;
};

float3 vor(float2 x, float time);
float2 hash(float2 p);

kernel void voronoi(texture2d<float, access::read>  inTexture   [[ texture(0)]],
                    texture2d<float, access::write> outTexture  [[ texture(1)]],
                    constant VoronoiUniforms &uniforms          [[ buffer(0) ]],
                    uint2 gid [[thread_position_in_grid]])
{
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 uv = (float2(gid) / size);
    float XYRatio = size.x / size.y;
    float density = (uniforms.size + 0.1) * 100.0;
    
    float2 p = uv;
    p.x *= XYRatio;
    
    float time = 1.0 + uniforms.time * uniforms.animate;
    
    float3 v = vor(density * p, time);
    float distance2border = v.x;
    float2 featurePt = v.yz;
    featurePt.x /= (density * XYRatio);
    featurePt.y /= density;
    
    float2 uvCenter = uv;
    uvCenter.x += featurePt.x;
    uvCenter.y += featurePt.y;
    uvCenter *= size;
    
    float3 color = inTexture.read(uint2(uvCenter)).rgb;
    color += float3(0.1);
    color = mix(float3(0.0, 0.0, 0.0), color, smoothstep( 0.0, 0.1, distance2border));
    
    outTexture.write(float4(color, 1.0), gid);
}

float2 hash(float2 p) {
    p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
    return fract(sin(p)*43758.5453);
}

float3 vor(float2 x, float time) {

    float2 n = floor(x);
    float2 f = fract(x);

    float2 mg, mr;

    float md = 8.0;
    for(int j = -1; j<=1; j++ ) {
        for(int i = -1; i <= 1; i++) {

            float2 g = float2(float(i), float(j));
            float2 o = hash(n + g);
            o = 0.5 + 0.5 * sin(time * 6.2831 * o);
            float2 r = g + o - f;

            //Euclidian distance
            float d = dot(r,r);

            if(d < md)
            {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    md = 8.0;
    for(int j = -2; j <= 2; j++) {
        for(int i = -2; i <= 2; i++) {
            
            float2 g = mg + float2(float(i), float(j));
            float2 o = hash(n + g);
            o = 0.5 + 0.5 * sin(time * 6.2831 * o);
            float2 r = g + o - f;

            if (length(mr - r) >= 0.0001) {
                // distance to line
                float d = dot( 0.5*(mr + r), normalize(r - mr));
                md = min(md, d);
            }
        }
    }
        
    return float3(md, mr);
}
