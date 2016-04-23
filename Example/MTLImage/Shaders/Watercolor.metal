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
    float distortion;
    float edgeDarkening;
    float turbulance;
};

float intensity(float3 color);
float average(float3 color);
float4 darken  (float4 base, float4 overlay);
float4 multiply(float4 base, float4 overlay);
float3 RGBToHSL(float3 color);
float3 HSLToRGB(float3 hsl);
float  HueToRGB(float f1, float f2, float hue);
float  cnoise(float2 P);

kernel void watercolor(texture2d<float, access::read>  inTexture     [[texture(0)]],
                       texture2d<float, access::write> outTexture    [[texture(1)]],
                       texture2d<float, access::read>  paperTexture  [[texture(2)]],
                       texture2d<float, access::read>  paperTexture2 [[texture(3)]],
                       constant WatercolorUniforms &uniforms         [[ buffer(0) ]],
                       uint2 gid                                     [[thread_position_in_grid]])
{
    

    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
    float2 paperSize   = float2(paperTexture.get_width(), paperTexture.get_height());
    float2 paper2Size  = float2(paperTexture2.get_width(), paperTexture2.get_height());
    float2 texCoord  = float2(gid) / textureSize;
    uint2  paperGid  = uint2(texCoord * paperSize);
    uint2  paperGid2 = uint2(texCoord * paper2Size);

//    Distortion
    uint2 distortionGid = gid + uint(1.0 - average(paperTexture.read(paperGid).rgb) * 10);
    float4 color = inTexture.read(distortionGid);
    
//    paperGid = gid + uint2(paperTexture.read(paperGid).xy) * uint(uniforms.distortion);
//    float4 color = inTexture.read(paperGid);
  
    float3 hsl = RGBToHSL(color.rgb);
    
//    Cell Shading
    float divisions = 8.0;
    hsl.z = (int(hsl.z * divisions))/divisions + 0.1;
    
    color.rgb = HSLToRGB(hsl);

    
//    Edge Darkening
    float bottomLeftIntensity  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
    float topRightIntensity    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
    float topLeftIntensity     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
    float bottomRightIntensity = inTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
    float leftIntensity        = inTexture.read(uint2(gid.x - 1, gid.y + 0)).r;
    float rightIntensity       = inTexture.read(uint2(gid.x + 1, gid.y + 0)).r;
    float bottomIntensity      = inTexture.read(uint2(gid.x + 0, gid.y - 1)).r;
    float topIntensity         = inTexture.read(uint2(gid.x + 0, gid.y + 1)).r;
    
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float magnitude = 1.0 - length(float2(h, v)) * uniforms.edgeDarkening * 2.0;
    if (magnitude < 0.5) //color = mix(color, magnitude, 0.25);
        color = float4(float3(magnitude), 1.0);
    
    
//    Turbulence flow / pigment dispersion
    
    float  n1 = (cnoise(float2(gid) * 0.2) + 1.0) / 2.0;
    float4 colorStart  = float4(1, 1, 1, 1);
    float4 colorFinish = float4(0, 0, 0, 1);
    float4 perlinNoise = colorStart + (colorFinish - colorStart) * n1;
    
    float I = intensity(perlinNoise.rgb);
    float d = 1 + uniforms.turbulance * (I - 0.5);
    if (average(color.rgb) < 0.95) {
        color = color * (1.0 - (1.0 - color) * (d - 1.0));
    }
    
    I = intensity(paperTexture2.read(paperGid2).rgb);
    d = 1 + uniforms.turbulance * (I - 0.5);
    if (average(color.rgb) < 0.95) {
        color = color * (1.0 - (1.0 - color) * (d - 1.0));
    }
    
//    overlay()
    
//    Paper Texture
    float4 paperColor = paperTexture.read(paperGid);
    if (average(color.rgb) > 0.9) color = darken(  color, paperColor);
    else                          color = multiply(color, paperColor);
    
    outTexture.write(color, gid);
}

float average(float3 color) {
    return (color.r + color.g + color.b)/3.0;
}

float intensity(float3 color) {
    return sqrt( 0.299 * (color.r * color.r) + 0.587 * (color.g * color.g) + 0.114 * (color.b * color.b));
}