//
//  Watercolor.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/20/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct WatercolorUniforms {
    
};

float3 WC_HSLToRGB(float3 hsl);
float3 WC_RGBToHSL(float3 color);
float WC_HueToRGB(float f1, float f2, float hue);

kernel void watercolor(texture2d<float, access::read>  inTexture  [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       constant WatercolorUniforms &uniforms      [[ buffer(0) ]],
                       uint2 gid                                  [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float3 hsl = WC_RGBToHSL(color.rgb);
    
    if      (hsl.b > 0.95) hsl.b = 0.95;
    else if (hsl.b > 0.75) hsl.b = 0.75;
    else if (hsl.b > 0.50) hsl.b = 0.50;
    else if (hsl.b > 0.25) hsl.b = 0.25;
    else                   hsl.b = 0.00;
    
    color.rgb = WC_HSLToRGB(hsl);
    outTexture.write(color, gid);
}

float3 WC_RGBToHSL(float3 color) {
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value
    
    hsl.z = (fmax + fmin) / 2.0; // Luminance
    
    if (delta == 0.0)		//This is a gray, no chroma...
    {
        hsl.x = 0.0;	// Hue
        hsl.y = 0.0;	// Saturation
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

float3 WC_HSLToRGB(float3 hsl) {
    float3 rgb;
    
    if (hsl.y == 0.0)
        rgb = float3(hsl.z); // Luminance
    else {
        float f2;
        
        if (hsl.z < 0.5) f2 = hsl.z * (1.0 + hsl.y);
        else             f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
        
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = WC_HueToRGB(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = WC_HueToRGB(f1, f2, hsl.x);
        rgb.b = WC_HueToRGB(f1, f2, hsl.x - (1.0/3.0));
    }
    
    return rgb;
}

float WC_HueToRGB(float f1, float f2, float hue) {
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
