//
//  ColorSelection.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float3 RGBtoXYZ(float3 color);
float3 XYZtoLAB(float3 color);
float convertValue(float value, float oldMin, float oldMax, float newMin, float newMax);
float compare(float3 rgb1, float3 rgb2, float tolerance, float min, float max);

struct ColorSelectionUniforms {
    float red;
    float orange;
    float yellow;
    float green;
    float aqua;
    float blue;
    float purple;
    float magenta;
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
};

float3 RGBtoXYZ(float3 color) {
    float r = color.r;
    float g = color.g;
    float b = color.b;
    
    if ( r > 0.04045 ) r = pow((( r + 0.055 ) / 1.055), 2.4);
    else               r = r / 12.92;
    if ( g > 0.04045 ) g = pow((( g + 0.055 ) / 1.055 ), 2.4);
    else               g = g / 12.92;
    if ( b > 0.04045 ) b = pow(((b + 0.055 ) / 1.055 ), 2.4);
    else               b = b / 12.92;
    
    r = r * 100.0;
    g = g * 100.0;
    b = b * 100.0;
    
    //Observer. = 2°, Illuminant = D65
    float X = r * 0.4124 + g * 0.3576 + b * 0.1805;
    float Y = r * 0.2126 + g * 0.7152 + b * 0.0722;
    float Z = r * 0.0193 + g * 0.1192 + b * 0.9505;
    
    return float3(X, Y, Z);
}

float3 XYZtoLAB(float3 color) {
    float x = color.x / 95.047;
    float y = color.y / 100.000;
    float z = color.z / 108.883;
    
    if ( x > 0.008856 ) x = pow(x ,(1.0/3.0));
    else                x = (7.787 * x) + (16.0 / 116.0);
    if ( y > 0.008856 ) y = pow(y ,(1.0/3.0));
    else                y = (7.787 * y) + (16.0 / 116.0);
    if ( z > 0.008856 ) z = pow(z ,(1.0/3.0));
    else                z = (7.787 * z) + (16.0 / 116.0);
    
    float L = (116.0 * y) - 16.0;
    float A = 500.0 * (x - y);
    float B = 200.0 * (y - z);
    
    return float3(L, A, B);
}

float convertValue(float value, float oldMin, float oldMax, float newMin, float newMax) {
    float normalizedValue = (value - oldMin)/(oldMax - oldMin);
    float newValue = newMin + (normalizedValue * (newMax - newMin));
    return newValue;
}

float compare(float3 rgb1, float3 rgb2, float tolerance, float min, float max) {
    
    float3 color1 = rgb1;
    float3 color2 = rgb2;
    
    float c1 = sqrt(color1.g * color1.g + color1.b * color1.b);
    float c2 = sqrt(color2.g * color2.g + color2.b * color2.b);
    
    float dc = c1 - c2;
    float dl = color1.r - color2.r;
    float da = color1.g - color2.g;
    float db = color1.b - color2.b;
    float dh = sqrt((da*da)+(db*db)-(dc*dc));
    float first  = dl;
    float second = dc/(1.0 + 0.045 * c1);
    float third  = dh/(1.0 + 0.015 * c1);
    
    float r = sqrt(first * first + second * second + third * third);
    
    min += tolerance;
    max += tolerance;
    
    if (r < min) return convertValue(r, min, max, 0.0, 1.0);
    return 0.0;
}

kernel void colorSelection(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                         texture2d<float, access::write> outTexture [[ texture(1) ]],
                         constant ColorSelectionUniforms &uniforms    [[ buffer(0) ]],
                         uint2    gid                               [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    Constants c;
    
    float redCompare;  float orangeCompare; float yellowCompare; float greenCompare;
    float aquaCompare; float blueCompare;   float purpleCompare; float magentaCompare;
    
    float opacity = 0.0;
    
    if (uniforms.red != 0.0) {
        redCompare = compare(c.redBase, color.rgb, c.redTolerance, 0.6, 1.7);
        opacity -= (redCompare * uniforms.red);
    }
    if (uniforms.orange != 0.0) {
        orangeCompare = compare(c.orangeBase , color.rgb, c.orangeTolerance, 0.35, 1.3);
        opacity -= (orangeCompare * uniforms.orange);
    }
    if (uniforms.yellow != 0.0) {
        yellowCompare = compare(c.yellowBase , color.rgb, c.yellowTolerance, 0.4, 2.3);
        opacity -= (yellowCompare * uniforms.yellow);
    }
    if (uniforms.green != 0.0) {
        greenCompare = compare(c.greenBase, color.rgb, c.greenTolerance, 0.5, 2.0);
        opacity -= (greenCompare * uniforms.green);
    }
    if (uniforms.aqua != 0.0) {
        aquaCompare = compare(c.aquaBase, color.rgb, c.aquaTolerance, 0.4, 1.2);
        opacity -= (aquaCompare * uniforms.aqua);
    }
    if (uniforms.blue != 0.0) {
        blueCompare = compare(c.blueBase, color.rgb, c.blueTolerance, 0.4, 1.0);
        opacity -= (blueCompare * uniforms.blue);
    }
    if (uniforms.purple != 0.0) {
        purpleCompare = compare(c.purpleBase ,color.rgb, c.purpleTolerance, 0.4, 1.1);
        opacity -= (purpleCompare * uniforms.purple);
    }
    if (uniforms.magenta != 0.0) {
        magentaCompare = compare(c.magentaBase, color.rgb, c.magentaTolerance, 0.5, 1.8);
        opacity -= (magentaCompare * uniforms.magenta);
    }
    
    opacity = clamp(opacity, 0.0, 1.0);
    
    outTexture.write(color, gid);
}