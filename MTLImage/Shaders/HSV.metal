//
//  HSV.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/29/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct HSVUniforms {
    float hue;
    float saturation;
    float vibrancy;
};

float3 RGBtoHSV(float3 rgb);
float3 HSVtoRGB(float3 hsv);

// r,g,b values are from 0 to 1
// h = [0,360], s = [0,1], v = [0,1]
//		if s == 0, then h = -1 (undefined)
float3 RGBtoHSV(float3 rgb) {
    float minimum, maximum, delta;
    float h, s, v;
    
    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;
    
    minimum = min(min(r, g), b );
    maximum = max(max(r, g), b );
    
    v = maximum;
    
    delta = maximum - minimum;
    if( maximum != 0 )
        s = delta / maximum;
    else {
        // r = g = b = 0		// s = 0, v is undefined
        s = 0;
        h = -1;
        return float3(h, s, v);
    }
    if(r == maximum)      h = 0 + ( g - b ) / delta;    // between yellow & magenta
    else if(g == maximum) h = 2 + ( b - r ) / delta;	// between cyan & yellow
    else                  h = 4 + ( r - g ) / delta;	// between magenta & cyan
    
    h *= 60;				// degrees
    
    if( h < 0 ) h += 360;
    
    return float3(h, s, v);
}

float3 HSVtoRGB(float3 hsv) {
    int i;
    float f, p, q, t;
    float r, g, b;
    
    float h = hsv.r;
    float s = hsv.g;
    float v = hsv.b;
    
    if( s == 0 ) {
        // achromatic (grey)
        return float3(v, v, v);
    }
    
    h /= 60;			// sector 0 to 5
    i = floor( h );
    f = h - i;			// factorial part of h
    p = v * ( 1 - s );
    q = v * ( 1 - s * f );
    t = v * ( 1 - s * ( 1 - f ) );
    switch( i ) {
        case 0:
            r = v;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = v;
            b = p;
            break;
        case 2:
            r = p;
            g = v;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = v;
            break;
        case 4:
            r = t;
            g = p;
            b = v;
            break;
        default:		// case 5:
            r = v;
            g = p;
            b = q;
            break;
    }
    
    return float3(r, g, b);
}

kernel void hsv(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                texture2d<float, access::write> outTexture [[ texture(1)]],
                constant HSVUniforms &uniforms             [[ buffer(0) ]],
                uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    float3 hsv = RGBtoHSV(color.rgb);
    
    hsv.r = fmod(hsv.r + uniforms.hue * 360, 360.0);
    hsv.g = uniforms.saturation;
//    hsv.b = uniforms.vibrancy;
    
    color.rgb = HSVtoRGB(hsv);
    
    outTexture.write(color, gid);
}