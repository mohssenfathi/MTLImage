//
//  Histogram.metal
//  MTLImage
//
//  Created by Mohammad Fathi on 4/25/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float3 W = float3(0.2125, 0.7154, 0.0721);
};

struct HistogramUniforms {
    float dummy;
};

kernel void histogram(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                      texture2d<float, access::write> outTexture [[ texture(1) ]],
                      constant HistogramUniforms &uniforms       [[ buffer(0)  ]],
                      device float *luminanceBuffer              [[ buffer(1)  ]],
                      device float *redBuffer                    [[ buffer(2)  ]],
                      device float *greenBuffer                  [[ buffer(3)  ]],
                      device float *blueBuffer                   [[ buffer(4)  ]],
                      uint2 gid                                  [[thread_position_in_grid]])
{
    
    
    float4 color = inTexture.read(gid);
    
    Constants c;
    float luminance = dot(color.rgb, c.W);
    
    luminanceBuffer[int(luminance * 255.0)] += 1.0;
    redBuffer      [int(color.r   * 255.0)] += 1.0;
    greenBuffer    [int(color.g   * 255.0)] += 1.0;
    blueBuffer     [int(color.b   * 255.0)] += 1.0;
    
    outTexture.write(color, gid);
}