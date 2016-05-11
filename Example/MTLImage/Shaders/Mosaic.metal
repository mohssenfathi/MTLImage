//
//  Mosaic.metal
//  Pods
//
//  Created by Mohssen Fathi on 5/6/16.
//
//

#include <metal_stdlib>
using namespace metal;

struct MosaicUniforms {
    float intensity;
};

kernel void mosaic(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                   texture2d<float, access::write> outTexture [[ texture(1) ]],
                   constant MosaicUniforms &uniforms          [[ buffer(0) ]],
                   uint2    gid                               [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    
//    
//    float rand(float co) { return fract(sin(co*(91.3458)) * 47453.5453); }
//    const int size = 30;
//    vec2 point[size];
//    vec3 color[size];
//    
//        float time = iGlobalTime;
//        vec2 position = fragCoord.xy / iResolution.xy;
//        vec2 uv = (fragCoord.xy/iResolution.xy)-.5;
//        uv.x /= iResolution.y/iResolution.x;
//        float circle_size = .01;
//        float allcircles=0.; float minimum; vec3 output_colors;
//        for(int i=0;i<size;i++){
//            float fi = float(i);
//            point[i] = vec2(cos((time*rand(fi+.15))+(rand(fi*2.)*14.)),sin((time*rand(fi+.4))+(rand(fi)*14.)))*.5 ;
//            color[i] = vec3(rand(fi),rand(fi+.2),rand(fi+.3))*1.5;
//            if(i==0){minimum=length(point[i]-uv);output_colors=color[i];}
//            allcircles+=step(length(uv-point[i]),circle_size);
//            if (length(point[i]-uv)<minimum) {
//                output_colors = color[i];
//                minimum = length(point[i]-uv);
//            }
//        }
//        fragColor = vec4(clamp(output_colors,0.,1.)-allcircles,1.0);
//
//    
//    float circleSize = 0.0;
//    float allCircles = 0.0;
//    float3 outputColors;
//    
//    for (int i = 0; i < int(uniforms.intensity); i++) {
//        float fi = float(i);
//        
//    }

    
    outTexture.write(color, gid);
}
