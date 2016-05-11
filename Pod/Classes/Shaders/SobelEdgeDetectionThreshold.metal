//
//  SobelEdgeDetectionThreshold.metal
//  Pods
//
//  Created by Mohssen Fathi on 5/9/16.
//
//

#include <metal_stdlib>
using namespace metal;

struct SobelEdgeDetectionThresholdUniforms {
    float threshold;
};

kernel void sobelEdgeDetectionThreshold(texture2d<float, access::read>               inTexture  [[ texture(0)]],
                                        texture2d<float, access::write>              outTexture [[ texture(1)]],
                                        constant SobelEdgeDetectionThresholdUniforms  &uniforms [[ buffer(0) ]],
                                        uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
    color.rgb = 1.0 - step(color.rgb, uniforms.threshold);
    
    outTexture.write(color, gid);
}