//
//  RectRenderer.metal
//  PT
//
//  Created by Mohssen Fathi on 9/5/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RectRendererUniforms {
    float x;
    float y;
    float width;
    float height;
    float lineWidth;
};

kernel void rectRenderer(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                         texture2d<float, access::write> outTexture [[ texture(1) ]],
                         constant RectRendererUniforms &uniforms       [[ buffer(0) ]],
                         uint2 gid [[thread_position_in_grid]])
{
    
    float4 color = inTexture.read(gid);
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    
    // temp
    if (uniforms.width > size.x * 0.99 || uniforms.height > size.y * 0.99) {
        outTexture.write(color, gid);
        return;
    }
    
    uint minX = uniforms.x;
    uint minY = uniforms.y;
    uint maxX = uniforms.x + uniforms.width;
    uint maxY = uniforms.y + uniforms.height;
    
    if (gid.x >= minX && gid.x <= maxX && gid.y >= minY && gid.y <= maxY) {
        
        if (abs(gid.x - minX) <= uniforms.lineWidth ||
            abs(gid.y - minY) <= uniforms.lineWidth ||
            abs(maxX - gid.x) <= uniforms.lineWidth ||
            abs(maxY - gid.y) <= uniforms.lineWidth) {
            
            color = float4(0, 1, 0, 1);
        }
    }
    
    outTexture.write(color, gid);
}
