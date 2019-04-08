//
//  chart_shaders.metal
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 06/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;


struct GlobalParameters
{
    float lineWidth;
    packed_float2 viewport;
    float3x3 transform;
    uint linePointsCount;
};

struct VertexOut {
    float4 pos[[position]];
    float4 color;
};

vertex VertexOut bezier_vertex(constant float2 *points[[buffer(0)]],
                               constant float4 *colors[[buffer(1)]],
                               constant GlobalParameters& globalParams[[buffer(2)]],
                               uint vertexId [[vertex_id]])
{
    uint wtfWhy = 4;
    uint chartIdx = vertexId / (wtfWhy*globalParams.linePointsCount);
    float2 p1 = points[vertexId / 4];
    float2 p2 = points[vertexId / 4 + 1];
    p1 = (globalParams.transform * float3(p1, 1)).xy;
    p2 = (globalParams.transform * float3(p2, 1)).xy;
    float2 tangent = p2 - p1;
    tangent = normalize(float2(-tangent.y, tangent.x));
    
    uint linePointOffset = ((vertexId / 2) % 2); // 0 or 1
    float2 point = points[vertexId / 4 + linePointOffset];
    point = (globalParams.transform * float3(point, 1)).xy;
    // This is a little trick to avoid conditional code. We need to determine which side of the
    // triangle we are processing, so as to calculate the correct "side" of the curve, so we just
    // check for odd vs. even vertexId values to determine that:
    float lineWidthOffset = (1 - (((float) (vertexId % 2)) * 2.0)) * globalParams.lineWidth / 2.0;
    
    VertexOut vo;
    
    // Combine the point with the tangent and lineWidth to achieve a properly oriented
    // triangle for this point in the curve:
    vo.pos.xy = point + (tangent * lineWidthOffset);
    vo.pos.xy = (vo.pos.xy / globalParams.viewport) * float2(2.0, 2.0) - float2(1,1);
    vo.pos.zw = float2(0, 1);
    vo.color = colors[chartIdx];
    
    return vo;
}

fragment float4 bezier_fragment(VertexOut params[[stage_in]])
{
    return params.color;
}
