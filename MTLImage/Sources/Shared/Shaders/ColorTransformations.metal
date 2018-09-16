//
//  ColorTransformations.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 11/15/17.
//

#include <metal_stdlib>
using namespace metal;

float3 rgb2hsv(float3 c);
float3 hsv2rgb(float3 c);
float3 hue( float3 s, float3 d);
float3 color( float3 s, float3 d);
float3 saturation( float3 s, float3 d );
float3 luminosity( float3 s, float3 d );
float3 RGBToHSL(float3 color);
float3 HSLToRGB(float3 hsl);
float HueToRGB(float f1, float f2, float hue);
float RGBToL(float3 color);
float3 RGBtoHSV(float3 rgb);
float3 RGBtoXYZ(float3 color);
float3 XYZtoLAB(float3 color);
float3 RGBtoLAB(float3 color);


//    rgb<-->hsv functions by Sam Hocevar
//    http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
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


float3 RGBToHSL(float3 color) {
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value
    
    hsl.z = (fmax + fmin) / 2.0; // Luminance
    
    if (delta == 0.0)        //This is a gray, no chroma...
    {
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
    }
    else                                    //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (fmax + fmin); // Saturation
        else
            hsl.y = delta / (2.0 - fmax - fmin); // Saturation
        
        float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;
        
        if (color.r == fmax )
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue
        
        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }
    
    return hsl;
}

float3 HSLToRGB(float3 hsl) {
    float3 rgb;
    
    if (hsl.y == 0.0)
        rgb = float3(hsl.z); // Luminance
    else {
        float f2;
        
        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
        
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = HueToRGB(f1, f2, hsl.x);
        rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
    }
    
    return rgb;
}

float HueToRGB(float f1, float f2, float hue) {
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

float RGBToL(float3 color) {
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    
    return (fmax + fmin) / 2.0; // Luminance
}

float3 RGBtoHSV(float3 rgb) {
    
    float3 hsv;
    float rgbMin, rgbMax;
    
    rgbMin = rgb.r < rgb.g ? (rgb.r < rgb.b ? rgb.r : rgb.b) : (rgb.g < rgb.b ? rgb.g : rgb.b);
    rgbMax = rgb.r > rgb.g ? (rgb.r > rgb.b ? rgb.r : rgb.b) : (rgb.g > rgb.b ? rgb.g : rgb.b);
    
    hsv.b = rgbMax;
    if (hsv.b == 0)
    {
        hsv.r = 0;
        hsv.g = 0;
        return hsv;
    }
    
    hsv.g = 1.0 * long(rgbMax - rgbMin) / hsv.b;
    if (hsv.g == 0)
    {
        hsv.r = 0;
        return hsv;
    }
    
    if (rgbMax == rgb.r)
        hsv.r = 0.0 + (43.0/255.0) * (rgb.g - rgb.b) / (rgbMax - rgbMin);
    else if (rgbMax == rgb.g)
        hsv.r = (85.0/255.0) + (43.0/255.0) * (rgb.b - rgb.r) / (rgbMax - rgbMin);
    else
        hsv.r = (171.0/255.0) + (43.0/255.0) * (rgb.r - rgb.g) / (rgbMax - rgbMin);
    
    return hsv;
}

float3 RGBtoXYZ(float3 color) {
    
    float3 tmp;
    tmp.x = ( color.r > 0.04045 ) ? pow( ( color.r + 0.055 ) / 1.055, 2.4 ) : color.r / 12.92;
    tmp.y = ( color.g > 0.04045 ) ? pow( ( color.g + 0.055 ) / 1.055, 2.4 ) : color.g / 12.92,
    tmp.z = ( color.b > 0.04045 ) ? pow( ( color.b + 0.055 ) / 1.055, 2.4 ) : color.b / 12.92;
    const float3x3 mat = float3x3(float3(0.4124, 0.3576, 0.1805),
                                  float3(0.2126, 0.7152, 0.0722),
                                  float3(0.0193, 0.1192, 0.9505));
    return 100.0 * (tmp * mat);
    
//    float r = color.r;
//    float g = color.g;
//    float b = color.b;
//
//    if ( r > 0.04045 ) r = pow((( r + 0.055 ) / 1.055), 2.4);
//    else               r = r / 12.92;
//    if ( g > 0.04045 ) g = pow((( g + 0.055 ) / 1.055 ), 2.4);
//    else               g = g / 12.92;
//    if ( b > 0.04045 ) b = pow(((b + 0.055 ) / 1.055 ), 2.4);
//    else               b = b / 12.92;
//
//    r = r * 100.0;
//    g = g * 100.0;
//    b = b * 100.0;
//
//    //Observer. = 2°, Illuminant = D65
//    float X = r * 0.4124 + g * 0.3576 + b * 0.1805;
//    float Y = r * 0.2126 + g * 0.7152 + b * 0.0722;
//    float Z = r * 0.0193 + g * 0.1192 + b * 0.9505;
//
//    return float3(X, Y, Z);
}

float3 XYZtoLAB(float3 color) {
    
    float3 n = color / float3(95.047, 100, 108.883);
    float3 v;
    v.x = ( n.x > 0.008856 ) ? pow( n.x, 1.0 / 3.0 ) : ( 7.787 * n.x ) + ( 16.0 / 116.0 );
    v.y = ( n.y > 0.008856 ) ? pow( n.y, 1.0 / 3.0 ) : ( 7.787 * n.y ) + ( 16.0 / 116.0 );
    v.z = ( n.z > 0.008856 ) ? pow( n.z, 1.0 / 3.0 ) : ( 7.787 * n.z ) + ( 16.0 / 116.0 );
    return float3(( 116.0 * v.y ) - 16.0, 500.0 * ( v.x - v.y ), 200.0 * ( v.y - v.z ));
    
//    float x = color.x / 95.047;
//    float y = color.y / 100.000;
//    float z = color.z / 108.883;
//
//    //    float x = color.x - 111.144;
//    //    float y = color.y - 100.000;
//    //    float z = color.z - 035.200;
//
//    if ( x > 0.008856 ) x = pow(x ,(1.0/3.0));
//    else                x = (7.787 * x) + (16.0 / 116.0);
//    if ( y > 0.008856 ) y = pow(y ,(1.0/3.0));
//    else                y = (7.787 * y) + (16.0 / 116.0);
//    if ( z > 0.008856 ) z = pow(z ,(1.0/3.0));
//    else                z = (7.787 * z) + (16.0 / 116.0);
//
//    float L = (116.0 * y) - 16.0;
//    float A = 500.0 * (x - y);
//    float B = 200.0 * (y - z);
//
//    return float3(L, A, B);
}

float3 RGBtoLAB(float3 color) {
    float3 lab = XYZtoLAB( RGBtoXYZ(color) );
    return float3( lab.x / 100.0, 0.5 + 0.5 * ( lab.y / 127.0 ), 0.5 + 0.5 * ( lab.z / 127.0 ));
}
