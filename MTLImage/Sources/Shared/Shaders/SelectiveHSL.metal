//
//  SelectiveHSL.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float3 RGBToHSL(float3 color);
float3 HSLToRGB(float3 hsl);

struct ColorSelectionUniforms {
    float3 red;
    float3 orange;
    float3 yellow;
    float3 green;
    float3 aqua;
    float3 blue;
    float3 purple;
    float3 magenta;
};

struct Constants {
    
    float red        = 00.0;
    float orange     = 30.0/360.0;
    float yellow     = 60.0/360.0;
    float green      = 120.0/360.0;
    float aqua       = 180.0/360.0;
    float blue       = 240.0/360.0;
    float purple     = 270.0/360.0;
    float magenta    = 300.0/360.0;
    
    const float4  kRGBToI     = float4 (0.595716, -0.274453, -0.321263, 0.0);
    const float4  kRGBToQ     = float4 (0.211456, -0.522591, 0.31135, 0.0);
    
    // Saturation / Luminance
    const float3 W = float3(0.2125, 0.7154, 0.0721);
};

float3 smoothTreatment(float3 hsv, float hueEdge0, float hueEdge1, float3 Edge0, float3 Edge1) {
    float smoothedHue = smoothstep(hueEdge0, hueEdge1, hsv.x);
    float hue = hsv.x + (Edge0.x + ((Edge1.x - Edge0.x) * smoothedHue));
    float sat = hsv.y * (Edge0.y + ((Edge1.y - Edge0.y) * smoothedHue));
    float lum = hsv.z * (Edge0.z + ((Edge1.z - Edge0.z) * smoothedHue));
    return float3(hue, sat, lum);
}


kernel void selectiveHSL(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                         texture2d<float, access::write> outTexture  [[ texture(1) ]],
                         texture2d<float, access::read>  adjustments [[ texture(2) ]],
                         constant ColorSelectionUniforms &uniforms   [[ buffer(0) ]],
                         uint2    gid                                [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float3 hsv = RGBToHSL(color.rgb);
    
    if (hsv.x < c.orange) {
        hsv = smoothTreatment(hsv, 0.0, orange, uniforms.red, uniforms.orange);
    }
    else if (hsv.x >= c.orange && hsv.x < c.yellow) {
        hsv = smoothTreatment(hsv, c.orange, yellow, uniforms.orange, uniforms.yellow);
    }
    else if (hsv.x >= c.yellow && hsv.x < c.green) {
        hsv = smoothTreatment(hsv, c.yellow, c.green, uniforms.yellow, uniforms.green);
    }
    else if (hsv.x >= c.green && hsv.x < c.aqua) {
        hsv = smoothTreatment(hsv, c.green, c.aqua, uniforms.green, uniforms.aqua);
    }
    else if (hsv.x >= c.aqua && hsv.x < c.blue) {
        hsv = smoothTreatment(hsv, c.aqua, c.blue, uniforms.aqua, uniforms.blue);
    }
    else if (hsv.x >= c.blue && hsv.x < c.purple)   {
        hsv = smoothTreatment(hsv, c.blue, c.purple, uniforms.blue, uniforms.purple);
    }
    else if (hsv.x >= c.purple && hsv.x < c.magenta){
        hsv = smoothTreatment(hsv, c.purple, c.magenta, uniforms.purple, uniforms.magenta);
    }
    else {
        hsv = smoothTreatment(hsv, c.magenta, 1.0, uniforms.magenta, uniforms.red);
    }

    outTexture.write(float4(HSLToRGB(hsv), 1.0), gid);
}

