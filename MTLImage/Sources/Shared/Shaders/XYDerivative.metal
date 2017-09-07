//
//  XYDerivative.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 5/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct XYDerivativeUniforms {
    float edgeStrength;
};

kernel void xyDerivative(texture2d<float, access::read>  inTexture  [[ texture(0)]],
                         texture2d<float, access::write> outTexture [[ texture(1)]],
                         constant XYDerivativeUniforms &uniforms    [[ buffer(0) ]],
                         uint2 gid [[thread_position_in_grid]])
{
    
    float bottom      = inTexture.read(uint2(gid.x    , gid.y - 1)).r;
    float bottomLeft  = inTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
    float bottomRight = inTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
    float left        = inTexture.read(uint2(gid.x - 1, gid.y    )).r;
    float right       = inTexture.read(uint2(gid.x + 1, gid.y    )).r;
    float top         = inTexture.read(uint2(gid.x    , gid.y + 1)).r;
    float topRight    = inTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
    float topLeft     = inTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
    
    float verticalDerivative = -topLeft - top - topRight + bottomLeft + bottom + bottomRight;
    float horizontalDerivative = -bottomLeft - left - topLeft + bottomRight + right + topRight;
    verticalDerivative = verticalDerivative * uniforms.edgeStrength;
    horizontalDerivative = horizontalDerivative * uniforms.edgeStrength;
    
    // Scaling the X * Y operation so that negative numbers are not clipped in the 0..1 range. This will be expanded in the corner detection filter
    float4 color = float4(horizontalDerivative * horizontalDerivative, verticalDerivative * verticalDerivative,
                          ((verticalDerivative * horizontalDerivative) + 1.0) / 2.0, 1.0);
    
    
    outTexture.write(color, gid);
}