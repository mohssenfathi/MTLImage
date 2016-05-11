//
//  LineDetection.metal
//  Pods
//
//  Created by Mohssen Fathi on 5/9/16.
//
//

#include <metal_stdlib>
using namespace metal;


struct LineDetectionUniforms {
    float sensitivity;
};

kernel void lineDetection(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                          texture2d<float, access::write> outTexture [[ texture(1)]],
                          constant LineDetectionUniforms &uniforms   [[ buffer(0) ]],
                          device float *accumulatorBuffer            [[ buffer(1) ]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
 
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
//    float2 uv = float2(gid)/size;
    
    // Should be passed in b/w image data. (Sobel Threshold or Canny Threshold)
    if (color.r > uniforms.sensitivity) {
        for (int i = 1; i <= 180; i++) {
            float r = gid.x * cos(float(i)) + gid.y * sin(float(i));
//            float x = float(i)/180.0 * size.x;
//            float y = r/10.0 * size.y;
//            float c = inTexture.read(uint2(x, y)).x;
//            if (c == 1.0) c = 0.0;
//            outTexture.write(float4(float3(c + (1.0/180.0)),1), uint2(x, y));
            accumulatorBuffer[uint(r * size.x + i)] += 1;
        }
    }
    
    outTexture.write(color, gid);
}