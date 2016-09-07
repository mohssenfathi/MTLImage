//
//  LensFlare.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 9/1/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//
// Adapted from 'Circle & Polygon Lens Flare'
// https://www.shadertoy.com/view/Xlc3D2


#include <metal_stdlib>
using namespace metal;

struct LensFlareUniforms {
    float r;
    float g;
    float b;
    
    float x;
    float y;
    
    float angleX;
    float angleY;
    
    float brightness;
    
    int showSun;
};


float rnd(float2 p);
float rnd(float w);
float regShape(float2 p, int N);
float3 circle(float2 p, float size, float decay, float3 color,float3 color2, float dist, float2 mouse);
float4 screen(float4 base, float4 overlay);


kernel void lensFlare(texture2d<float, access::read>  inTexture   [[ texture(0)]],
                      texture2d<float, access::write> outTexture  [[ texture(1)]],
                      constant LensFlareUniforms &uniforms        [[ buffer(0) ]],
                      uint2 gid [[thread_position_in_grid]])
{
    
    float4 originalColor = inTexture.read(gid);
    
    // Size is kinda slow. Look at this later
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 uv = (float2(gid) / size);
    uv.x -= uniforms.angleX;
    uv.y -= uniforms.angleY;
    uv.x *= size.x/size.y; //fix aspect ratio
    
    float2 pos = float2(uniforms.x, uniforms.y) - 0.5;
    pos.x *= size.x/size.y; //fix aspect ratio

    //now to make the sky not black
    //    float3 color = mix(float3(0.3, 0.2, 0.02)/0.9, float3(0.2, 0.5, 0.8), uv.y) * 3.0 - 0.52;
    float3 color = float3(uniforms.r, uniforms.g, uniforms.b);
    
    float3 circColor  = mix(float3(0.9, 0.2, 0.1), color, 0.5);
    float3 circColor2 = mix(float3(0.3, 0.1, 0.9), color, 0.5);
    
    //this calls the function which adds three circle types every time through the loop based on parameters I
    //got by trying things out. rnd i*2000. and rnd i*20 are just to help randomize things more
    for(float i = 0.0; i < 5.0; i += 1.0) {
        color += circle(uv, pow(rnd(i * 2000.0) * 1.8, 2.0) + 1.41, uniforms.brightness * 50.0, circColor + i,
                                circColor2 + i, rnd(i * 20.0) * 3.0 + 0.2 - 0.5, pos);
    }
    
//    float3 circle(float2 p, float size, float decay, float3 color, float3 color2, float dist, float2 mouse)
    
    //get angle and length of the sun (uv - pos)
    float a = atan2(uv.y - pos.y, uv.x - pos.x);
//    float l = max(1.0 - length(uv - pos) - 0.84, 0.0);
    
    //add brightness based on how the sun moves so that it is brightest
    //when it is lined up with the center
    float bright = uniforms.brightness;
    
    //add the sun with the frill things
    if (uniforms.showSun) {
        color += max(0.1 / pow(length(uv - pos) * 5.00, 5.0), 0.0) * abs(sin(a * 5.0 + cos(a * 9.0)))/20.0;
        color += max(0.1 / pow(length(uv - pos) * 10.0, 1.0 / 20.0), 0.0) +
                    abs(sin(a * 3.0 + cos(a * 9.0))) / 8.0 * (abs(sin(a * 9.0))) / 1.0;
    }
    
    //add another sun in the middle (to make it brighter)  with the20color I want, and bright as the numerator.
    color += (max(bright / pow(length(uv - pos) * 4.0, 1.0 / 2.0), 0.0) * 4.0) * float3(0.2, 0.21, 0.3) * 4.0;
    // * (0.5+.5*sin(float3(0.4, 0.2, 0.1) + float3(a*2., 00., a*3.)+1.3));
    
    //multiply by the exponetial e^x ? of 1.0-length which kind of masks the brightness more so that
    //there is a sharper roll of of the light decay from the sun.
    color *= exp(1.0 - length(uv - pos)) / 5.0; //(uniforms.brightness * 10.0);
    

    color = screen(float4(color, 1.0), originalColor).rgb;
    
    outTexture.write(float4(color, 1.0), gid);
}


float rnd(float2 p) {
    float f = fract(sin(dot(p, float2(12.1234, 72.8392) ) * 45123.2));
    return f;
}

float rnd(float w) {
    float f = fract(sin(w) * 1000.0);
    return f;
}

float regShape(float2 p, int N) {
    float f;
    
    float a = atan2(p.x, p.y) + 0.2;
    float b = 6.28319 / float(N);
    f = smoothstep(0.5, 0.51, cos(floor(0.5 + a / b) * b - a) * length(p.xy));
    
    return f;
}

float3 circle(float2 p, float size, float decay, float3 color, float3 color2, float dist, float2 mouse) {
    
    //l is used for making rings.I get the length and pass it through a sinwave
    //but I also use a pow function. pow function + sin function , from 0 and up, = a pulse, at least
    //if you return the max of that and 0.0.
    
    float l = length(p + mouse * (dist * 4.0)) + size / 2.0;
    
    //l2 is used in the rings as well...somehow...
//    float l2 = length(p + mouse*(dist*4.))+size/3.;
    
    ///these are circles, big, rings, and  tiny respectively
//    float c  = max(00.01 - pow(length(p + mouse * dist), size * 1.4), 0.0) * 50.0;
    float c1 = max(0.001 - pow(l - 0.3, 1.0 / 40.0) + sin(l * 30.0), 0.0) * 3.0;
    float c2 = max(0.040 / pow(length(p - mouse * dist / 2.0 + 0.09) * 1.0, 1.0), 0.0) / 20.0;
    float s  = max(00.01 - pow(regShape(p * 5.0 + mouse * dist * 5.0 + 0.9, 6) , 1.0), 0.0) * 5.0;
    
   	color = 0.5 + 0.5 * sin(color);
    color = cos(float3(0.44, 0.24, 0.2) * 8.0 + dist * 4.0) * 0.5 + 0.5;
    
//    float3 f = c * color;
//    f += c1 * color;
    float3 f = c1 * color;
    f += c2 * color;
    f +=  s * color;
    
    f *= pow(decay, 4.0);
    
    return f - 0.01;
}



/*

float3 lensflare(float2 uv, float2 pos, float noi);
float3 cc(float3 color, float factor,float factor2);
float noise(float  t);
float noise(float2 t);
float4 overlay(float4 base, float4 overlay);

kernel void lensFlare(texture2d<float, access::read>  inTexture   [[ texture(0)]],
                      texture2d<float, access::write> outTexture  [[ texture(1)]],
                      texture2d<float, access::read>  noise       [[ texture(2)]],
                      constant LensFlareUniforms &uniforms        [[ buffer(0) ]],
                      uint2 gid [[thread_position_in_grid]])
{
//    float4 color = inTexture.read(gid);
    
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
//    float2 uv = float2(float(gid.x)/size.x, float(gid.y)/size.y);

    
    float2 uv = (float2(gid) / size) - 0.5;
    uv.x *= size.x/size.y; //fix aspect ratio
    float2 pos = float2(uniforms.x, uniforms.y) - 0.5;
    pos.x *= size.x/size.y; //fix aspect ratio
    
//    float2 pos = float2(uniforms.x, uniforms.y);
//    float2 main = uv - pos;
//    float  ang  = atan2(main.x, main.y);
    
    // Noise
//    uint x = ((pos.x + pos.y) * 2.2 + ang * 4.0 + 5.954) * noise.get_width();
    float3 noiseColor = noise.read(gid).rgb;
    float a = (noiseColor.r + noiseColor.g + noiseColor.b)/3.0;

    
    float3 color = float3(uniforms.r, uniforms.g, uniforms.b) * lensflare(uv, pos, a);
//    color -= noise(fragCoord.xy) * .015;
    color = cc(color, 0.5, 0.1);
    
    float4 outColor = float4(color, 1.0); overlay(inTexture.read(gid), float4(color, 1.0));
    
    outTexture.write(outColor, gid);
}

//float noise(float t) {
//    
//    uint x = t * noise.get_width();
//    return noise.read(uint2(x, 0)).x;
////    return texture2D(iChannel0, float2(t, 0.0) / iChannelResolution[0].xy).x;
//}
//
//float noise(float2 t) {
//    
//    uint2 x = uint2(t * float2(noise.get_width(), noise.get_height()));
//    return noise.read(x).x;
////    return texture2D(iChannel0, t / iChannelResolution[0].xy).x;
//}


float3 lensflare(float2 uv, float2 pos, float noi)
{
    float2 uvd  = uv * (length(uv));
    float2 main = uv - pos;
    float  dist = length(main);
    dist = pow(dist, 0.1);
    
//    float n = noise(float2(ang * 16.0, dist * 32.0), noi);
    
    float f0 = 1.0 / (length(uv - pos) * 16.0 + 1.0);
//    f0 = f0 + f0 * (sin(noi * 16.0) * 0.1 + dist * 0.1 + 0.8);
    
//    float f1 = max(0.01 - pow(length(uv + 1.2 * pos), 1.9), 0.0) * 7.0;
    
    float f2  = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.80 * pos), 2.0)), 0.0) * 0.25;
    float f22 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.85 * pos), 2.0)), 0.0) * 0.23;
    float f23 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.90 * pos), 2.0)), 0.0) * 0.21;
    
    float2 uvx = mix(uv,uvd,-0.5);
    
    float f4  = max(0.01 - pow(length(uvx + 0.40 * pos), 2.4), 0.0) * 6.0;
    float f42 = max(0.01 - pow(length(uvx + 0.45 * pos), 2.4), 0.0) * 5.0;
    float f43 = max(0.01 - pow(length(uvx + 0.50 * pos), 2.4), 0.0) * 3.0;
    
    uvx = mix(uv, uvd, -0.4);
    
    float f5  = max(0.01 - pow(length(uvx + 0.2 * pos), 5.5), 0.0) * 2.0;
    float f52 = max(0.01 - pow(length(uvx + 0.4 * pos), 5.5), 0.0) * 2.0;
    float f53 = max(0.01 - pow(length(uvx + 0.6 * pos), 5.5), 0.0) * 2.0;
    
    uvx = mix(uv,uvd,-0.5);
    
    float f6  = max(0.01 - pow(length(uvx - 0.300 * pos), 1.6), 0.0) * 6.0;
    float f62 = max(0.01 - pow(length(uvx - 0.325 * pos), 1.6), 0.0) * 3.0;
    float f63 = max(0.01 - pow(length(uvx - 0.350 * pos), 1.6), 0.0) * 5.0;
    
    float3 c = float3(0.0);
    
    c.r += f2 + f4 + f5 + f6;
    c.g += f22 + f42 + f52 + f62;
    c.b += f23 + f43 + f53 + f63;
    c = c * 1.3 - float3(length(uvd) * 0.05);
    c += float3(f0);
    
    return c;
}

float3 cc(float3 color, float factor,float factor2) // color modifier
{
    float w = color.x + color.y + color.z;
    return mix(color, float3(w) * factor, w * factor2);
}
*/
