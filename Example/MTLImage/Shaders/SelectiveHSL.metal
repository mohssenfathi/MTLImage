//
//  SelectiveHSL.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float3 RGBtoXYZ(float3 color);
float3 XYZtoLAB(float3 color);
float3 RGBToHSL(float3 color);
float3 HSLToRGB(float3 hsl);
float HueToRGB(float f1, float f2, float hue);
float RGBToL(float3 color);
float convertValue(float value, float oldMin, float oldMax, float newMin, float newMax);
float compare(float3 rgb1, float3 rgb2, float tolerance, float min, float max);
float map_hue(float hueShift[7], int range, float value);
float map_saturation(float saturationShift[7], int range, float value);
float map_lightness(float lightnessShift[7], int range, float value);

struct ColorSelectionUniforms {
//    float red;
//    float orange;
//    float yellow;
//    float green;
//    float aqua;
//    float blue;
//    float purple;
//    float magenta;
    int mode;
};

struct Constants {
    float3 redBase     = float3(1.0, 0.0, 0.0);
    float3 orangeBase  = float3(1.0, 0.5, 0.0);
    float3 yellowBase  = float3(1.0, 1.0, 0.0);
    float3 greenBase   = float3(0.0, 1.0, 0.0);
    float3 aquaBase    = float3(0.0, 1.0, 1.0);
    float3 blueBase    = float3(0.0, 0.0, 1.0);
    float3 purpleBase  = float3(0.5, 0.0, 0.5);
    float3 magentaBase = float3(1.0, 0.0, 1.0);
    
    float redTolerance     = 0.4;
    float orangeTolerance  = 0.4;
    float yellowTolerance  = 0.4;
    float greenTolerance   = 0.4;
    float aquaTolerance    = 0.4;
    float blueTolerance    = 0.4;
    float purpleTolerance  = 0.4;
    float magentaTolerance = 0.4;
    
    const float4  kRGBToYPrime = float4 (0.299, 0.587, 0.114, 0.0);
    const float4  kRGBToI     = float4 (0.595716, -0.274453, -0.321263, 0.0);
    const float4  kRGBToQ     = float4 (0.211456, -0.522591, 0.31135, 0.0);
    
    const float4  kYIQToR   = float4 (1.0, 0.9563, 0.6210, 0.0);
    const float4  kYIQToG   = float4 (1.0, -0.2721, -0.6474, 0.0);
    const float4  kYIQToB   = float4 (1.0, -1.1070, 1.7046, 0.0);
    
    const float overlap = 0.1;
    
    // Saturation / Luminance
    const float3 W = float3(0.2125, 0.7154, 0.0721);
};

float3 RGBToHSL(float3 color) {
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

float map_hue(float hueShift[7], int range, float value) {
    value += (hueShift[0] + hueShift[range]) / 2.0;
    
    if (value < 0.0)
        return value + 1.0;
    else if (value > 1.0)
        return value - 1.0;
    else
        return value;
}

float map_saturation(float saturationShift[7], int range, float value) {
    float v = saturationShift[0] + saturationShift[range];
    value *= (v + 1.0);
    return clamp(value, 0.0, 1.0);
}

float map_lightness(float lightnessShift[7], int range, float value) {
    float v = (lightnessShift[0] + lightnessShift[range]) / 2.0;
    
    if (v < 0.0) return value * (v + 1.0);
    else         return value + (v * (1.0 - value));
}


kernel void selectiveHSL(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                         texture2d<float, access::write> outTexture  [[ texture(1) ]],
                         texture2d<float, access::read>  adjustments [[ texture(2) ]],
                         constant ColorSelectionUniforms &uniforms   [[ buffer(0) ]],
                         uint2    gid                                [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    Constants c;
    
    float3 hsl = RGBToHSL(color.rgb);
    float h = hsl.x * 6.0;
    
    int hue_counter;
    int hue = 0;
    int secondary_hue = 0;
    int use_secondary_hue = 0; // TODO: Should be of bool type
    float primary_intensity   = 0.0;
    float secondary_intensity = 0.0;
    
    for (hue_counter = 0; hue_counter < 7; hue_counter++) {
        float hue_threshold = float(hue_counter) + 0.5;
        
        if (h < (hue_threshold + c.overlap)) {
            hue = hue_counter;
            
            if (c.overlap > 0.0 && h > (hue_threshold - c.overlap)) {
                use_secondary_hue = 1;
                secondary_hue = hue_counter + 1;
                secondary_intensity = (h - hue_threshold + c.overlap) / (2.0 * c.overlap);
                primary_intensity = 1.0 - secondary_intensity;
            } else {
                use_secondary_hue = 0;
            }
            break;
        }
    }
    
    if (hue >= 6) {
        hue = 0;
        use_secondary_hue = 0;
    }
    
    if (secondary_hue >= 6) {
        secondary_hue = 0;
    }
    
    // transform into GPUHueRange values
    hue++;
    secondary_hue++;
    
    float hueShift[7];
    float saturationShift[7];
    float lightnessShift[7];
    for (int i = 0; i < 7; i++) {
        hueShift[i]        = adjustments.read(uint2(1 * i, 1)).r;
        saturationShift[i] = adjustments.read(uint2(2 * i, 1)).r;
        lightnessShift[i]  = adjustments.read(uint2(3 * i, 1)).r;
    }
    
    if (use_secondary_hue == 1) {
        float mapped_primary_hue;
        float mapped_secondary_hue;
        float diff;
        
        mapped_primary_hue   = map_hue(hueShift, hue, hsl.x);
        mapped_secondary_hue = map_hue(hueShift, secondary_hue, hsl.x);
        
        // Find nearest hue on the circle between primary and secondary hue
        diff = mapped_primary_hue - mapped_secondary_hue;
        if (diff < -0.5) {
            mapped_secondary_hue -= 1.0;
        } else if (diff >= 0.5) {
            mapped_secondary_hue += 1.0;
        }
        
        hsl.x = (mapped_primary_hue   * primary_intensity +
                 mapped_secondary_hue * secondary_intensity);
        
        hsl.y = (map_saturation(saturationShift, hue, hsl.y) * primary_intensity +
                 map_saturation(saturationShift, secondary_hue, hsl.y) * secondary_intensity);
        
        hsl.z = (map_lightness(lightnessShift, hue,           hsl.z) * primary_intensity +
                 map_lightness(lightnessShift, secondary_hue, hsl.z) * secondary_intensity);
    } else {
        hsl.x = map_hue       (hueShift, hue, hsl.x);
        hsl.y = map_saturation(saturationShift, hue, hsl.y);
        hsl.z = map_lightness (lightnessShift, hue, hsl.z);
    }
    
    color.rgb = HSLToRGB(hsl);

    outTexture.write(color, gid);
}

//kernel void selectiveHSL1(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
//                           texture2d<float, access::write> outTexture [[ texture(1) ]],
//                           constant ColorSelectionUniforms &uniforms    [[ buffer(0) ]],
//                           uint2    gid                               [[thread_position_in_grid]])
//{
//    float4 color = inTexture.read(gid);
//    Constants c;
//    
//    float value;
//    float originalValue;
//    float redCompare, orangeCompare, yellowCompare, greenCompare, aquaCompare, blueCompare, purpleCompare, magentaCompare;
//    
//    // Hue specific
//    float YPrime, I, Q, chroma;
//    
//    if (uniforms.mode == 0) {        // hue
//        YPrime = dot(color, c.kRGBToYPrime);
//        I      = dot(color, c.kRGBToI);
//        Q      = dot(color, c.kRGBToQ);
//        chroma = sqrt (I * I + Q * Q);
//        value  = atan2(Q, I);
//    } else if (uniforms.mode == 1 || uniforms.mode == 2) { // saturation, luminance
//        value = dot(color.rgb, c.W);
//    }
//    originalValue = value;
//    
//    float adjust = 0.0;
//    if (uniforms.red != 0.0) {
//        redCompare = compare(c.redBase, color.rgb, c.redTolerance, 0.6, 1.7);
//        adjust += (redCompare * uniforms.red * 1.0);
//    }
//    if (uniforms.orange != 0.0) {
//        orangeCompare = compare(c.orangeBase , color.rgb, c.orangeTolerance, 0.35, 1.3);
//        adjust += (orangeCompare * uniforms.orange * 1.0);
//    }
//    if (uniforms.yellow != 0.0) {
//        yellowCompare = compare(c.yellowBase , color.rgb, c.yellowTolerance, 0.6, 2.2);
//        adjust += (yellowCompare * uniforms.yellow *  2.5);
//    }
//    if (uniforms.green != 0.0) {
//        greenCompare = compare(c.greenBase, color.rgb, c.greenTolerance, 0.5, 2.0);
//        adjust += (greenCompare * uniforms.green * 3.0);
//    }
//    if (uniforms.aqua != 0.0) {
//        aquaCompare = compare(c.aquaBase, color.rgb, c.aquaTolerance, 0.4, 1.2);
//        adjust += (aquaCompare * uniforms.aqua * 1.0);
//    }
//    if (uniforms.blue != 0.0) {
//        blueCompare = compare(c.blueBase, color.rgb, c.blueTolerance, 0.4, 1.0);
//        adjust += (blueCompare * uniforms.blue * 1.0);
//    }
//    if (uniforms.purple != 0.0) {
//        purpleCompare = compare(c.purpleBase ,color.rgb, c.purpleTolerance, 0.4, 1.1);
//        adjust += (purpleCompare * uniforms.purple * 1.0);
//    }
//    if (uniforms.magenta != 0.0) {
//        magentaCompare = compare(c.magentaBase, color.rgb, c.magentaTolerance, 0.5, 1.8);
//        adjust += (magentaCompare * uniforms.magenta * 1.0);
//    }
//    
//    if (uniforms.mode == 0) {        // hue
//        value += adjust;
//        Q = chroma * sin (value);
//        I = chroma * cos (value);
//        
//        float4 yIQ = float4(YPrime, I, Q, 0.0);
//        color.r = dot (yIQ, c.kYIQToR);
//        color.g = dot (yIQ, c.kYIQToG);
//        color.b = dot (yIQ, c.kYIQToB);
//    }
//    else if (uniforms.mode == 1) { // saturation
//        color = float4(mix(float3(value), color.rgb, 1.0 - adjust), color.a);
//    }
//    else if (uniforms.mode == 2) { //  luminance
//        //         value += ;
//        //         value = mix(value, originalValue, 0.4);
//        //         value = clamp(value, 0.0, 1.0);
//        //         color = float4(float3(value),color.a);
//        
//        float3 hsl = RGBToHSL(color.rgb);
//        hsl.z -= (adjust/3.0);
//        color.rgb = HSLToRGB(hsl);
//    }
//    
//    outTexture.write(color, gid);
//}