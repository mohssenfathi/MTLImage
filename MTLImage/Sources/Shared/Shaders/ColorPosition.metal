//
//  ColorRect.metal
//  Tracker
//
//  Created by Mohssen Fathi on 7/27/17.
//  Copyright © 2017 Mohssen Fathi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ColorPositionUniforms {
    float threshold = 0.5;
};

/*
    IDEA:
 
        To get multiple separate sets, use disjoint set.
        Return buffer in form:
            [# of sets,  xmin, xmax, ymin, ymax,  xmin, xmax, ymin, ymax,  ... ]
 */

kernel void colorPosition(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                          texture2d<float, access::write> outTexture [[ texture(1) ]],
                          constant ColorPositionUniforms &uniforms   [[ buffer(0) ]],
                          device float *outputRect                   [[ buffer(1)  ]],
                          uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    uint2 size = uint2(inTexture.get_width(), inTexture.get_height());
    
    
    /* rect: [minX, maxX, minY, maxY] */
    
    // Set defaults
    if (gid.x + gid.y == 0) {
        outputRect[0] = float(size.x);
        outputRect[1] = 0.0;
        outputRect[2] = float(size.y);
        outputRect[3] = 0.0;
    }

//    if (outputRect[3] < 0) {
//        outputRect[0] = float(size.x);
//        outputRect[1] = 0.0;
//        outputRect[2] = float(size.y);
//        outputRect[3] = 0.0;
//    }

    if (color.a > 0.0) {

        if (gid.x < outputRect[0]) {
            outputRect[0] = float(gid.x);
            outTexture.write(color, gid);
            return;
        }
        else if (gid.x > outputRect[1]) {
            outputRect[1] = float(gid.x);
        }
        
        if (gid.y < outputRect[2]) {
            outputRect[2] = float(gid.y);
        }
        else if (gid.y > outputRect[3]) {
            outputRect[3] = float(gid.y);
        }

    }

    outTexture.write(color, gid);
}

