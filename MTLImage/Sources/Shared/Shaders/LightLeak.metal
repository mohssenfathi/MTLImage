//
//  LightLeak.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 11/12/17.
//

#include <metal_stdlib>
using namespace metal;

struct LightLeakUniforms {
    float time;
};

kernel void lightLeak(texture2d<float, access::read>  inTexture  [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      constant LightLeakUniforms &uniforms      [[ buffer(0) ]],
                      uint2 gid [[thread_position_in_grid]])
{
//    float4 color = inTexture.read(gid);
//    outTexture.write(color, gid);
    
    float2 size = float2(inTexture.get_width(), inTexture.get_height());
    float2 p = float2(gid) / size;
     
    for(int i = 1; i < 6; i++) {
         float2 newp = p;
         newp.x += 0.6 / float(i) * cos(float(i) * p.y + (1.0 * 10.0) / 10.0 + 0.3 * float(i)) + 400. / 20.0;
         newp.y += 0.6 / float(i) * cos(float(i) * p.x + (1.0 * 10.0) / 10.0 + 0.3 * float(i + 10)) - 400. / 20.0 + 15.0;
         p = newp;
     }
    
    float3 color = float3(0.5 * sin(3.0 * p.x) + 0.5, 0.5 * sin(3.0 * p.y) + 0.5, sin(p.x + p.y));
    outTexture.write(float4(color, 1.0), gid);
}
