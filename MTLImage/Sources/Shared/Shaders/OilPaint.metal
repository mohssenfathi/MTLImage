
//
//  OilPaint.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


float  rand(float2 co);
float  noise2f(float2 p);
float  fbm(float2 c);
float2 cMul(float2 a, float2 b);
float  pattern(float2 p, float2 q, float2 r, float time);
float3 rgb2hsv(float3 c);
float3 hsv2rgb(float3 c);
float3 hue(float3 s, float3 d);
float3 color(float3 s, float3 d);
float3 saturation(float3 s, float3 d );
float3 luminosity(float3 s, float3 d );

struct OilPaintUniforms {
    float time;
};

struct Constants {
    const int radius = 10;
    const float3 color1 = float3(0.101961,0.619608,0.666667);
    const float3 color2 = float3(0.666667,0.666667,0.498039);
    const float3 color3 = float3(0,0,0.164706);
    const float3 color4 = float3(0.666667,1,1);
};

kernel void oilPaint(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant OilPaintUniforms &uniforms        [[ buffer(0) ]],
                     uint2    gid                               [[thread_position_in_grid]])
{
    Constants constants;
    float4 color = inTexture.read(gid);
    
    outTexture.write(color, gid);
}

//kernel void oilPaint(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
//                     texture2d<float, access::write> outTexture [[ texture(1) ]],
//                     constant OilPaintUniforms &uniforms        [[ buffer(0) ]],
//                     uint2    gid                               [[thread_position_in_grid]])
//{
//    Constants constants;
//    float4 color = inTexture.read(gid);
//    
//    
//    float2 src_size = float2 (inTexture.get_width(), inTexture.get_height());
//    float2 uv = float2(gid)/src_size;
//    float n = float((constants.radius + 1) * (constants.radius + 1));
//    int i;
//    int j;
//    float3 m0 = float3(0.0); float3 m1 = float3(0.0); float3 m2 = float3(0.0); float3 m3 = float3(0.0);
//    float3 s0 = float3(0.0); float3 s1 = float3(0.0); float3 s2 = float3(0.0); float3 s3 = float3(0.0);
//    float3 c;
//    
//    float2 q;
//    float2 r;
//    float2 c3 = 1000.0 * uv;
//    float f = pattern(c3 * 0.01, q, r, uniforms.time);
//    float3 col = mix(constants.color1, constants.color2, clamp((f * f) * 4.0, 0.0, 1.0));
//    col = constants.color2;
//    col = mix(col, constants.color3,clamp(length(q), 0.0, 1.0));
//    col = mix(col, constants.color4,clamp(length(r.x), 0.0, 1.0));
//    
//    float3 col2 = (0.2*f*f*f+0.6*f*f+0.5*f)*col;
//    float2 delta =  col2.xy * 0.025;
//    
//    const float3 lumi = float3(0.2126, 0.7152, 0.0722);
//    
//    float3 hc = sample(-1,-1,delta,fragCoord) *  1.0 + sample( 0,-1,delta,fragCoord) *  2.0
//                + sample( 1,-1,delta,fragCoord) *  1.0 + sample(-1, 1,delta,fragCoord) * -1.0
//                + sample( 0, 1,delta,fragCoord) * -2.0 + sample( 1, 1,delta,fragCoord) * -1.0;
//    
//    float3 vc =sample(-1,-1,delta,fragCoord) *  1.0 + sample(-1, 0,delta,fragCoord) *  2.0
//		 	+sample(-1, 1,delta,fragCoord) *  1.0 + sample( 1,-1,delta,fragCoord) * -1.0
//		 	+sample( 1, 0,delta,fragCoord) * -2.0 + sample( 1, 1,delta,fragCoord) * -1.0;
//    
//    float3 c2 = sample(0, 0,delta,fragCoord);
//    
//    c2 -= pow(c2, float3(0.2126, 0.7152, 0.0722)) * pow(dot(lumi, vc*vc + hc*hc), 0.5);
//    
//    
//    uv = uv + delta;
//    
//    for (int j = -radius; j <= 0; ++j)  {
//        for (int i = -radius; i <= 0; ++i)  {
//            c = texture2D(iChannel0, uv + float2(i,j) * src_size).rgb;
//            m0 += c;
//            s0 += c * c;
//        }
//    }
//    
//    for (int j = -radius; j <= 0; ++j)  {
//        for (int i = 0; i <= radius; ++i)  {
//            c = texture2D(iChannel0, uv + float2(i,j) * src_size).rgb;
//            m1 += c;
//            s1 += c * c;
//        }
//    }
//    
//    for (int j = 0; j <= radius; ++j)  {
//        for (int i = 0; i <= radius; ++i)  {
//            c = texture2D(iChannel0, uv + float2(i,j) * src_size).rgb;
//            m2 += c;
//            s2 += c * c;
//        }
//    }
//    
//    for (int j = 0; j <= radius; ++j)  {
//        for (int i = -radius; i <= 0; ++i)  {
//            c = texture2D(iChannel0, uv + float2(i,j) * src_size).rgb;
//            m3 += c;
//            s3 += c * c;
//        }
//    }
//    
//    
//    float4 result;
//    float min_sigma2 = 1e+2;
//    m0 /= n;
//    s0 = abs(s0 / n - m0 * m0);
//    
//    float sigma2 = s0.r + s0.g + s0.b;
//    if (sigma2 < min_sigma2) {
//        min_sigma2 = sigma2;
//        result = float4(m0, 1.0);
//    }
//    
//    m1 /= n;
//    s1 = abs(s1 / n - m1 * m1);
//    
//    sigma2 = s1.r + s1.g + s1.b;
//    if (sigma2 < min_sigma2) {
//        min_sigma2 = sigma2;
//        result = float4(m1, 1.0);
//    }
//    
//    m2 /= n;
//    s2 = abs(s2 / n - m2 * m2);
//    
//    sigma2 = s2.r + s2.g + s2.b;
//    if (sigma2 < min_sigma2) {
//        min_sigma2 = sigma2;
//        result = float4(m2, 1.0);
//    }
//    
//    m3 /= n;
//    s3 = abs(s3 / n - m3 * m3);
//    
//    sigma2 = s3.r + s3.g + s3.b;
//    if (sigma2 < min_sigma2) {
//        min_sigma2 = sigma2;
//        result = float4(m3, 1.0);
//    }
//    
//    
//    float4 res2 = float4(overlay(screen( result.rgb,c2.rgb), result.rgb) , 1.0);
//    
//    float3 col3 = texture2D(iChannel0, fragCoord.xy / iResolution.xy + col2.xy * 0.05 ).xyz;
//    
//    fragColor = float4(saturation(col3,res2.rgb ),1.0);
//    
//    
//    outTexture.write(color, gid);
//}

float rand(float2 co) {
    // implementation found at: lumina.sourceforge.net/Tutorials/Noise.html
    return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

float noise2f(float2 p) {
    float2 ip = float2(floor(p));
    float2 u = fract(p);
    // http://www.iquilezles.org/www/articles/morenoise/morenoise.htm
    u = u * u * (3.0 - 2.0 * u);
    //u = u*u*u*((6.0*u-15.0)*u+10.0);
    
    float res = mix(
                    mix(rand(ip),  rand(ip+float2(1.0,0.0)),u.x),
                    mix(rand(ip+float2(0.0,1.0)),   rand(ip+float2(1.0,1.0)),u.x),
                    u.y)
    ;
    return res*res;
    //return 2.0* (res-10.7);
}

float fbm(float2 c) {
    float f = 0.0;
    float w = 1.0;
    for (int i = 0; i < 8; i++) {
        f += w * noise2f(c);
        c *= 2.0;
        w *= 0.5;
    }
    return f;
}


float2 cMul(float2 a, float2 b) {
    return float2( a.x * b.x -  a.y * b.y, a.x * b.y + a.y * b.x);
}

float pattern(float2 p, float2 q, float2 r, float time) {
    q.x = fbm( p + 0.00 * time * 2.0); // @SLIDER: 5. could represent velocity of water
    q.y = fbm( p + float2(1.0));
    
    r.x = fbm( p + 1.0 * q + float2(1.7,9.2) + 0.150 * time * 2.0);
    r.y = fbm( p + 1.0 * q + float2(8.3,2.8) + 0.126 * time * 2.0);
    //r = cMul(q,q+0.1*time);
    return fbm(p + 1.0 * r + 0.0 * time);
}

//	rgb<-->hsv functions by Sam Hocevar
//	http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float3 hue( float3 s, float3 d) {
    d = rgb2hsv(d);
    d.x = rgb2hsv(s).x;
    return hsv2rgb(d);
}

float3 color( float3 s, float3 d) {
    s = rgb2hsv(s);
    s.z = rgb2hsv(d).z;
    return hsv2rgb(s);
}

float3 saturation( float3 s, float3 d )
{
    d = rgb2hsv(d);
    d.y = rgb2hsv(s).y;
    return hsv2rgb(d);
}

float3 luminosity( float3 s, float3 d )
{
    float dLum = dot(d, float3(0.3, 0.59, 0.11));
    float sLum = dot(s, float3(0.3, 0.59, 0.11));
    float lum = sLum - dLum;
    float3 c = d + lum;
    float minC = min(min(c.x, c.y), c.z);
    float maxC = max(max(c.x, c.y), c.z);
    if(minC < 0.0) return sLum + ((c - sLum) * sLum) / (sLum - minC);
    else if(maxC > 1.0) return sLum + ((c - sLum) * (1.0 - sLum)) / (maxC - sLum);
    else return c;
}

//float3 sample(const int x, const int y, float2 delta, float2 fragCoord)
//{
//    float2 uv = (fragCoord.xy + float2(x, y)) / iResolution.xy;
//    uv = uv + delta;
//    //uv.y = 1.0 - uv.y;
//    
//    return texture2D(iChannel0, uv).xyz;
//}
