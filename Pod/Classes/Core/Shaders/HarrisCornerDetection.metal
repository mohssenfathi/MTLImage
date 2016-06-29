//
//  HarrisCornerDetection.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct HarrisCornerDetectionUniforms {
    float sensitivity;
};

struct Constants {
    float harrisConstant = 0.04;
};

kernel void harrisCornerDetection(texture2d<float, access::read>  inTexture        [[ texture(0)]],
                                  texture2d<float, access::write> outTexture       [[ texture(1)]],
                                  constant HarrisCornerDetectionUniforms &uniforms [[ buffer(0) ]],
                                  uint2 gid [[thread_position_in_grid]])
{
    Constants c;
    
    float3 derivativeElements = inTexture.read(gid).rgb;
    float derivativeSum = derivativeElements.x + derivativeElements.y;
    float zElement = (derivativeElements.z * 2.0) - 1.0;
    float cornerness = derivativeElements.x * derivativeElements.y - (zElement * zElement) - c.harrisConstant * derivativeSum * derivativeSum;

    outTexture.write(float4(float3(cornerness * uniforms.sensitivity), 1.0), gid);
}


struct HarrisCornerDetectionOutputUniforms {
    
};

kernel void harrisCornerDetectionOutput(texture2d<float, access::read>  inTexture              [[ texture(0)]],
                                        texture2d<float, access::write> outTexture             [[ texture(1)]],
                                        texture2d<float, access::read>  originalTexture        [[ texture(2)]],
                                        constant HarrisCornerDetectionOutputUniforms &uniforms [[ buffer(0) ]],
                                        uint2 gid [[thread_position_in_grid]])
{
    float4 color = originalTexture.read(gid);
    float corner = inTexture.read(gid).r;
    
    if (corner > 0.0) {
        color = float4(1, 0, 0, 1); // Change to different color later
        outTexture.write(color, gid);
        for (int i = 0; i < 3; i++) {
            outTexture.write(color, uint2(gid.x, gid.y - i));
            outTexture.write(color, uint2(gid.x + i, gid.y));
            outTexture.write(color, uint2(gid.x, gid.y + i));
            outTexture.write(color, uint2(gid.x - i, gid.y));
        }
    }
    else {
        outTexture.write(color, gid);
    }
}