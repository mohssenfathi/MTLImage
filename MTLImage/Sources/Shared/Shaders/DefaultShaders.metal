//
//  Shaders.metal
//  MTLImage
//
//  Created by Mohssen Fathi on 3/25/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


typedef struct {
    float4 position [[position]];
    float2 coordinate;
} TextureMappingVertex;



vertex TextureMappingVertex vertex_main(unsigned int vertex_id [[ vertex_id ]]) {
    float4x4 position = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),      /// (x, y, depth, W)
                                 float4(  1.0, -1.0, 0.0, 1.0 ),
                                 float4( -1.0,  1.0, 0.0, 1.0 ),
                                 float4(  1.0,  1.0, 0.0, 1.0 ));

    float4x2 coordinates = float4x2(float2( 0.0, 1.0 ), /// (x, y)
                                    float2( 1.0, 1.0 ),
                                    float2( 0.0, 0.0 ),
                                    float2( 1.0, 0.0 ));
    
//    coordinates = transformMatrix * vec4(position.xyz, 1.0) * orthographicMatrix
    
    TextureMappingVertex outVertex;
    outVertex.position = position[vertex_id];
    outVertex.coordinate = coordinates[vertex_id];;

    return outVertex;
}

fragment half4 fragment_main(TextureMappingVertex mappingVertex [[ stage_in ]],
                             texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    return half4(texture.sample(s, mappingVertex.coordinate));
}

