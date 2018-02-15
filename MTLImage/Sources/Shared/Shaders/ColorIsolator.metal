//
//  ColorIsolator.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 1/5/18.
//

#include <metal_stdlib>
using namespace metal;

float3 RGBtoXYZ(float3 color);
float3 XYZtoLAB(float3 color);
float deltaE(float3 labA, float3 labB);

struct ColorIsolatorUniforms {
    float4 color;
    float threshold;
};

kernel void colorIsolator(texture2d<float, access::read>  inTexture    [[ texture(0) ]],
                          texture2d<float, access::write> outTexture   [[ texture(1) ]],
                          constant ColorIsolatorUniforms &uniforms     [[ buffer(0) ]],
                          uint2 gid [[thread_position_in_grid]]) {
    
    
    float4 col = inTexture.read(gid);
    
    float3 labA = RGBtoXYZ(XYZtoLAB(col.rgb));
    float3 labB = RGBtoXYZ(XYZtoLAB(uniforms.color.rgb));
    
    float delta = deltaE(labA, labB);

//    float delta = sqrt(pow(labB.r - labA.r, 2) + pow(labB.g - labA.g, 2) + pow(labB.b - labA.b, 2))/1000.0;

    outTexture.write(float4(labB/255.0, 1.0), gid);
//    outTexture.write(float4(float3(delta), 1.0), gid);
    return;
    
    if (delta < uniforms.threshold) {
        outTexture.write(col, gid);
        return;
    }

    outTexture.write(float4(0, 0, 0, 0), gid);
}





float deltaE(float3 labA, float3 labB) {
    
    float deltaL = labA[0] - labB[0];
    float deltaA = labA[1] - labB[1];
    float deltaB = labA[2] - labB[2];
    float c1 = sqrt(labA[1] * labA[1] + labA[2] * labA[2]);
    float c2 = sqrt(labB[1] * labB[1] + labB[2] * labB[2]);
    float deltaC = c1 - c2;
    float deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
    deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
    
    float sc = 1.0 + 0.045 * c1;
    float sh = 1.0 + 0.015 * c1;
    float deltaLKlsl = deltaL / (1.0);
    float deltaCkcsc = deltaC / (sc);
    float deltaHkhsh = deltaH / (sh);
    float i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;
    
    return i < 0 ? 0 : sqrt(i);
}
