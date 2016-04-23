//
//  Blend.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 4/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlendUniforms {
    float mix;
    float blendMode;
};

// Used
float4 overlay      (float4 base, float4 overlay);
float4 lighten      (float4 base, float4 overlay);
float4 darken       (float4 base, float4 overlay);
float4 softLight    (float4 base, float4 overlay);
float4 hardLight    (float4 base, float4 overlay);
float4 multiply     (float4 base, float4 overlay);
float4 subtract     (float4 base, float4 overlay);
float4 divide       (float4 base, float4 overlay);
float4 colorBurn    (float4 base, float4 overlay);
float4 colorDodge   (float4 base, float4 overlay);
float4 screen       (float4 base, float4 overlay);
float4 difference   (float4 base, float4 overlay);

// Not used
float3 linearBurn   (float3 base, float3 overlay);
float4 linearDodge  (float4 base, float4 overlay);
float3 lighterColor (float3 base, float3 overlay);
float3 darkerColor  (float3 base, float3 overlay);
float  vividLight   (float  base, float  overlay);
float3 vividLight   (float3 base, float3 overlay);
float3 linearLight  (float3 base, float3 overlay);
float4 pinLight     (float4 base, float4 overlay);


kernel void blend(texture2d<float, access::read>  inTexture    [[ texture(0) ]],
                  texture2d<float, access::write> outTexture   [[ texture(1) ]],
                  texture2d<float, access::read>  blendTexture [[ texture(2) ]],
                  constant BlendUniforms &uniforms             [[ buffer(0) ]],
                  uint2 gid [[thread_position_in_grid]])
{
    
    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
    float2 blendSize   = float2(blendTexture.get_width(), blendTexture.get_height());
    float2 texCoord  = float2(gid) / textureSize;
    uint2  blendGid = uint2(texCoord * blendSize);
    
    float4 color = inTexture.read(gid);
    float4 blendColor = blendTexture.read(blendGid);
    blendColor.a = uniforms.mix;

    int mode = uniforms.blendMode;
    
    if (mode == 0) {  // Normal
        float a = color.a + blendColor.a * (1.0 - color.a);
        float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output
        float4 outColor;
        
        outColor.r = (blendColor.r * blendColor.a + color.r * color.a * (1.0 - blendColor.a))/alphaDivisor;
        outColor.g = (blendColor.g * blendColor.a + color.g * color.a * (1.0 - blendColor.a))/alphaDivisor;
        outColor.b = (blendColor.b * blendColor.a + color.b * color.a * (1.0 - blendColor.a))/alphaDivisor;
        outColor.a = a;
        
        outTexture.write(outColor, gid);
    }
    else if (mode == 1) { // Overlay
        outTexture.write(overlay(color, blendColor), gid);
    }
    else if (mode == 2) { // Lighten
        outTexture.write(lighten(color, blendColor), gid);
    }
    else if (mode == 3) { // Darken
        outTexture.write(darken(color, blendColor), gid);
    }
    else if (mode == 4) { // Soft Light
        outTexture.write(softLight(color, blendColor), gid);
    }
    else if (mode == 5) { // Hard Light
        outTexture.write(hardLight(color, blendColor), gid);
    }
    else if (mode == 6) { // Multiply
        outTexture.write(multiply(color, blendColor), gid);
    }
    else if (mode == 7) { // Subtract
        outTexture.write(subtract(color, blendColor), gid);
    }
    else if (mode == 8) { // Divide
        outTexture.write(divide(color, blendColor), gid);
    }
    else if (mode == 9) { // Color Burn
        outTexture.write(colorBurn(color, blendColor), gid);
    }
    else if (mode == 10) { // Color Dodge
        outTexture.write(colorDodge(color, blendColor), gid);
    }
    else if (mode == 11) { // Screen
        outTexture.write(screen(color, blendColor), gid);
    }
    else if (mode == 12) { // Difference
        outTexture.write(difference(color, blendColor), gid);
    }
}


// Blend Modes

float4 darken(float4 base, float4 overlay) {
    return float4(min(overlay.rgb * base.a, base.rgb * overlay.a) +
                  overlay.rgb * (1.0 - base.a) +
                  base.rgb * (1.0 - overlay.a), 1.0);
}

float4 multiply( float4 base, float4 overlay) {
    return float4(base.rgb * overlay.rgb, base.a);
}

float4 subtract( float4 base, float4 overlay) {
    return float4(base.rgb - overlay.rgb, base.a);
}

float4 divide( float4 base, float4 overlay) {
    return float4(base.rgb / overlay.rgb, base.a);
}

float4 colorBurn( float4 base, float4 overlay) {
    return float4(1.0 - (1.0 - overlay.rgb) / base.rgb, base.a);
}

float3 linearBurn( float3 base, float3 overlay) {
    return base + overlay - 1.0;
}

//float3 darkerColor( float3 base, float3 overlay) {
//    return (base.x + base.y + base.z < overlay.x + overlay.y + overlay.z) ? s : d;
//}

float4 lighten(float4 base, float4 overlay) {
    return max(base, overlay);
}

float4 screen(float4 base, float4 overlay) {
    float4 whiteColor = float4(1.0);
    return whiteColor - ((whiteColor - overlay) * (whiteColor - base));
}

float4 colorDodge( float4 base, float4 overlay) {
    float3 baseOverlayAlphaProduct = float3(overlay.a * base.a);
    float3 rightHandProduct = overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a);
    float3 firstBlendColor = baseOverlayAlphaProduct + rightHandProduct;
    float3 overlayRGB = clamp((overlay.rgb / clamp(overlay.a, 0.01, 1.0)) * step(0.0, overlay.a), 0.0, 0.99);
    float3 secondBlendColor = (base.rgb * overlay.a) / (1.0 - overlayRGB) + rightHandProduct;
    float3 colorChoice = step((overlay.rgb * base.a + base.rgb * overlay.a), baseOverlayAlphaProduct);
    
    return float4(mix(firstBlendColor, secondBlendColor, colorChoice), 1.0);
}

float4 linearDodge(float4 base, float4 overlay) {
    return base + overlay;
}

float3 lighterColor( float3 base, float3 overlay) {
    return (base.x + base.y + base.z > overlay.x + overlay.y + overlay.z) ? base : overlay;
}

float4 overlay( float4 base, float4 overlay) {
    
    float ra;
    if (2.0 * base.r < base.a) {
        ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    }
    
    float ga;
    if (2.0 * base.g < base.a) {
        ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    }
    
    float ba;
    if (2.0 * base.b < base.a) {
        ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    }
    
    return float4(ra, ga, ba, 1.0);
}

float4 softLight( float4 base, float4 overlay) {
    float alphaDivisor = base.a + step(base.a, 0.0);
    return base * (overlay.a * (base / alphaDivisor) +
                   (2.0 * overlay * (1.0 - (base / alphaDivisor)))) +
    overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
}

float4 hardLight( float4 base, float4 overlay) {
    float ra;
    if (2.0 * overlay.r < overlay.a) {
        ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    }
    
    float ga;
    if (2.0 * overlay.g < overlay.a) {
        ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    }
    
    float ba;
    if (2.0 * overlay.b < overlay.a) {
        ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    }
    
    return float4(ra, ga, ba, 1.0);
}

float vividLight( float base, float overlay) {
    return (base < 0.5) ? 1.0 - (1.0 - overlay) / (2.0 * base) : overlay / (2.0 * (1.0 - base));
}

//float4 vividLight( float4 base, float4 overlay) {
//    float4 c;
//    c.x = vividLight(base.x, overlay.x);
//    c.y = vividLight(base.y, overlay.y);
//    c.z = vividLight(base.z, overlay.z);
//    c.w = vividLight(base.w, overlay.w);
//    return c;
//}
//
//float4 linearLight( float4 base, float4 overlay) {
//    return 2.0 * base + overlay - 1.0;
//}
//
//float pinLight( float base, float overlay) {
//    return (2.0 * base - 1.0 > overlay) ? 2.0 * base - 1.0 : (base < 0.5 * overlay) ? 2.0 * base : overlay;
//}

//float4 pinLight( float4 base, float4 overlay) {
//    float4 c;
//    c.x = pinLight(base.x, overlay.x);
//    c.y = pinLight(base.y, overlay.y);
//    c.z = pinLight(base.z, overlay.z);
//    c.w = pinLight(base.w, overlay.w);
//    return c;
//}

//float3 hardMix( float3 base, float3 overlay) {
//    return floor(s + overlay);
//}

float4 difference(float4 base, float4 overlay) {
    return float4(abs(overlay.rgb - base.rgb), base.a);
}

//float3 exclusion( float3 base, float3 overlay) {
//    return s + d - 2.0 * s * d;
//}
