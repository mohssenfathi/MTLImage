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
float4 add          (float4 base, float4 overlay);
float4 alpha        (float4 base, float4 overlay, float mixValue);
float4 colorBlend   (float4 base, float4 overlay, float mixValue);
float4 colorBurn    (float4 base, float4 overlay);
float4 colorDodge   (float4 base, float4 overlay);
float4 darken       (float4 base, float4 overlay);
float4 difference   (float4 base, float4 overlay);
float4 disolve      (float4 base, float4 overlay, float mixValue);
float4 divide       (float4 base, float4 overlay);
float4 exclusion    (float4 base, float4 overlay);
float4 hardLight    (float4 base, float4 overlay);
float4 linearBurn   (float4 base, float4 overlay);
float4 lighten      (float4 base, float4 overlay);
float4 linearDodge  (float4 base, float4 overlay);
float4 lumosity     (float4 base, float4 overlay);
float4 multiply     (float4 base, float4 overlay);
float4 normal       (float4 base, float4 overlay);
float4 overlay      (float4 base, float4 overlay);
float4 screen       (float4 base, float4 overlay);
float4 softLight    (float4 base, float4 overlay);
float4 subtract     (float4 base, float4 overlay);

// Not used
float3 linearBurn   (float3 base, float3 overlay);
float4 linearDodge  (float4 base, float4 overlay);
float3 lighterColor (float3 base, float3 overlay);
float3 darkerColor  (float3 base, float3 overlay);
float  vividLight   (float  base, float  overlay);
float3 vividLight   (float3 base, float3 overlay);
float3 linearLight  (float3 base, float3 overlay);
float4 pinLight     (float4 base, float4 overlay);

// Helpers
float  lum(float3);
float3 clipcolor(float3 c);
float3 setlum(float3 c, float l);

kernel void blend(texture2d<float, access::read>  inTexture    [[ texture(0) ]],
                  texture2d<float, access::write> outTexture   [[ texture(1) ]],
                  texture2d<float, access::read>  blendTexture [[ texture(2) ]],
                  constant BlendUniforms &uniforms             [[ buffer(0) ]],
                  uint2 gid [[thread_position_in_grid]])
{

    int mode = uniforms.blendMode;
    
    // These are causing some issues
//    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
//    float2 blendSize   = float2(blendTexture.get_width(), blendTexture.get_height());
//    float2 texCoord  = float2(gid) / textureSize;
//    uint2  blendGid = uint2(texCoord * blendSize);
    
    float4 outColor = float4(0);
    float4 color = inTexture.read(gid);
    float4 blendColor = blendTexture.read(gid); //blendGid);
    
    if (mode != 1 && mode != 2 && mode != 7) {
        blendColor.a = uniforms.mix;
    }
    
    if      (mode == 0)  outColor = add         (color, blendColor);
    else if (mode == 1)  outColor = alpha       (color, blendColor, uniforms.mix);
    else if (mode == 2)  outColor = colorBlend  (color, blendColor, uniforms.mix);
    else if (mode == 3)  outColor = colorBurn   (color, blendColor);
    else if (mode == 4)  outColor = colorDodge  (color, blendColor);
    else if (mode == 5)  outColor = darken      (color, blendColor);
    else if (mode == 6)  outColor = difference  (color, blendColor);
    else if (mode == 7)  outColor = disolve     (color, blendColor, uniforms.mix);
    else if (mode == 8)  outColor = divide      (color, blendColor);
    else if (mode == 9)  outColor = exclusion   (color, blendColor);
    else if (mode == 10) outColor = hardLight   (color, blendColor);
    else if (mode == 11) outColor = lighten     (color, blendColor);
    else if (mode == 12) outColor = linearBurn  (color, blendColor);
    else if (mode == 13) outColor = linearDodge (color, blendColor);
    else if (mode == 14) outColor = lumosity    (color, blendColor);
    else if (mode == 15) outColor = multiply    (color, blendColor);
    else if (mode == 16) outColor = normal      (color, blendColor);
    else if (mode == 17) outColor = overlay     (color, blendColor);
    else if (mode == 18) outColor = screen      (color, blendColor);
    else if (mode == 19) outColor = softLight   (color, blendColor);
    else if (mode == 20) outColor = subtract    (color, blendColor);

    outTexture.write(outColor, gid);

}


// Blend Modes

float4 add(float4 base, float4 overlay) {

    float r;
    if (overlay.r * base.a + base.r * overlay.a >= overlay.a * base.a) {
        r = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        r = overlay.r + base.r;
    }
    
    float g;
    if (overlay.g * base.a + base.g * overlay.a >= overlay.a * base.a) {
        g = overlay.a * base.a + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        g = overlay.g + base.g;
    }
    
    float b;
    if (overlay.b * base.a + base.b * overlay.a >= overlay.a * base.a) {
        b = overlay.a * base.a + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        b = overlay.b + base.b;
    }
    
    float a = overlay.a + base.a - overlay.a * base.a;
    
    return float4(r, g, b, a);
}

float4 alpha(float4 base, float4 overlay, float mixValue) {
    return float4(mix(base.rgb, overlay.rgb, overlay.a * mixValue), base.a);
}

float4 colorBlend(float4 base, float4 overlay, float mixValue) {
    return float4(base.rgb * (1.0 - overlay.a) + setlum(overlay.rgb, lum(base.rgb)) * overlay.a, base.a);
}

float4 colorBurn(float4 base, float4 overlay) {
    float4 whiteColor = float4(1.0);
    return whiteColor - (whiteColor - base) / overlay;
    //    return float4(1.0 - (1.0 - overlay.rgb) / base.rgb, base.a);
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

float4 darken(float4 base, float4 overlay) {
    return float4(min(overlay.rgb * base.a, base.rgb * overlay.a) +
                  overlay.rgb * (1.0 - base.a) +
                  base.rgb * (1.0 - overlay.a), 1.0);
}

float4 difference(float4 base, float4 overlay) {
    return float4(abs(overlay.rgb - base.rgb), base.a);
}

float4 disolve(float4 base, float4 overlay, float mixValue) {
    return mix(base, overlay, mixValue);
}

float4 divide( float4 base, float4 overlay) {
//    return float4(base.rgb / overlay.rgb, base.a);
    
    float ra;
    if (overlay.a == 0.0 || ((base.r / overlay.r) > (base.a / overlay.a)))
        ra = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    else
        ra = (base.r * overlay.a * overlay.a) / overlay.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    
    
    float ga;
    if (overlay.a == 0.0 || ((base.g / overlay.g) > (base.a / overlay.a)))
        ga = overlay.a * base.a + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    else
        ga = (base.g * overlay.a * overlay.a) / overlay.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    
    
    float ba;
    if (overlay.a == 0.0 || ((base.b / overlay.b) > (base.a / overlay.a)))
        ba = overlay.a * base.a + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    else
        ba = (base.b * overlay.a * overlay.a) / overlay.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    
    float a = overlay.a + base.a - overlay.a * base.a;
    
    return float4(ra, ga, ba, a);
}

float4 exclusion(float4 base, float4 overlay) {
    return float4((overlay.rgb * base.a + base.rgb * overlay.a - 2.0 * overlay.rgb * base.rgb) + overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a), base.a);
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

float4 linearBurn(float4 base, float4 overlay) {
    return float4(clamp(base.rgb + overlay.rgb - float3(1.0), float3(1.0), float3(1.0)), base.a);
}

float4 lighten(float4 base, float4 overlay) {
    return max(base, overlay);
}

float4 linearDodge(float4 base, float4 overlay) {
    return base + overlay;
}

float4 lumosity(float4 base, float4 overlay) {
    return float4(base.rgb * (1.0 - overlay.a) + setlum(base.rgb, lum(overlay.rgb)) * overlay.a, base.a);
}

float4 multiply(float4 base, float4 overlay) {
    //    return float4(base.rgb * overlay.rgb, base.a);
    return overlay * base + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
}

float4 normal(float4 base, float4 overlay) {
    
//    float a = color.a + blendColor.a * (1.0 - color.a);
//    float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output
//    float4 outColor;
//    
//    outColor.r = (blendColor.r * blendColor.a + color.r * color.a * (1.0 - blendColor.a))/alphaDivisor;
//    outColor.g = (blendColor.g * blendColor.a + color.g * color.a * (1.0 - blendColor.a))/alphaDivisor;
//    outColor.b = (blendColor.b * blendColor.a + color.b * color.a * (1.0 - blendColor.a))/alphaDivisor;
//    outColor.a = a;
//    
//    outTexture.write(outColor, gid);
    
    float4 outputColor;
    
    float a = base.a + overlay.a * (1.0 - base.a);
    float alphaDivisor = a + step(a, 0.0);
    
    outputColor.r = (base.r * base.a + overlay.r * overlay.a * (1.0 - base.a))/alphaDivisor;
    outputColor.g = (base.g * base.a + overlay.g * overlay.a * (1.0 - base.a))/alphaDivisor;
    outputColor.b = (base.b * base.a + overlay.b * overlay.a * (1.0 - base.a))/alphaDivisor;
    outputColor.a = a;
    
    return outputColor;
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

float4 screen(float4 base, float4 overlay) {
    float4 whiteColor = float4(1.0);
    return whiteColor - ((whiteColor - overlay) * (whiteColor - base));
}

float4 softLight( float4 base, float4 overlay) {
    float alphaDivisor = base.a + step(base.a, 0.0);
    return base * (overlay.a * (base / alphaDivisor) + (2.0 * overlay * (1.0 - (base / alphaDivisor)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
}

float4 subtract(float4 base, float4 overlay) {
    return float4(base.rgb - overlay.rgb, base.a);
}



// Unused

//float vividLight( float base, float overlay) {
//    return (base < 0.5) ? 1.0 - (1.0 - overlay) / (2.0 * base) : overlay / (2.0 * (1.0 - base));
//}
//
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
//
//float4 pinLight( float4 base, float4 overlay) {
//    float4 c;
//    c.x = pinLight(base.x, overlay.x);
//    c.y = pinLight(base.y, overlay.y);
//    c.z = pinLight(base.z, overlay.z);
//    c.w = pinLight(base.w, overlay.w);
//    return c;
//}
//
//float3 hardMix( float3 base, float3 overlay) {
//    return floor(s + overlay);
//}
//
//float3 darkerColor( float3 base, float3 overlay) {
//    return (base.x + base.y + base.z < overlay.x + overlay.y + overlay.z) ? s : d;
//}
//
//float3 lighterColor(float3 base, float3 overlay) {
//    return (base.x + base.y + base.z > overlay.x + overlay.y + overlay.z) ? base : overlay;
//}


// Helpers

float lum(float3 color) {
    return dot(color, float3(0.2125, 0.7154, 0.0721));
}

float3 clipcolor(float3 c) {
    float l = lum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    
    if (n < 0.0) {
        c.r = l + ((c.r - l) * l) / (l - n);
        c.g = l + ((c.g - l) * l) / (l - n);
        c.b = l + ((c.b - l) * l) / (l - n);
    }
    if (x > 1.0) {
        c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
        c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
        c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
    }
    
    return c;
}

float3 setlum(float3 c, float l) {
    float d = l - lum(c);
    c = c + float3(d);
    return clipcolor(c);
}
