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
    packed_float2 halfViewport;
    float3x3 transform;
    uint linePointsCount;
    uint chartCount;
};


struct LevelIn {
    float y;
    float4 color;
};

struct VertexOut {
    float4 pos[[position]];
    float4 color;
};

vertex VertexOut line_vertex(constant float2 *points[[buffer(0)]],
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
    vo.pos.xy = (vo.pos.xy / globalParams.halfViewport) - float2(1,1);
    vo.pos.zw = float2(0, 1);
    vo.color = colors[chartIdx];
    
    return vo;
}

vertex VertexOut stacked_fill_vertex(constant float2 *points[[buffer(0)]],
                                     constant float4 *colors[[buffer(1)]],
                                     constant GlobalParameters& globalParams[[buffer(2)]],
                                     uint vertexId [[vertex_id]])
{
    uint wtfWhy = 4;
    uint chartIdx = vertexId / (wtfWhy * globalParams.linePointsCount);
    float yVal = 0;
    uint pointId = vertexId / 4;
    uint pointOffset = pointId % globalParams.linePointsCount;
    
    for (uint i = 0; i <= chartIdx; i++) {
        yVal += points[pointOffset + i * globalParams.linePointsCount].y * colors[i].w;
    }
    float2 p1 = points[pointId];
    p1.y = yVal;
    float2 p0 = float2(p1.x, 0);
    
    
    uint linePointOffset = ((vertexId / 2) % 2); // 0 or 1
    float2 point = float(linePointOffset) * (p1-p0) + p0;
    
    // This is a little trick to avoid conditional code. We need to determine which side of the
    // triangle we are processing, so as to calculate the correct "side" of the curve, so we just
    // check for odd vs. even vertexId values to determine that:
    float lineWidthOffset = (1 - (((float) (vertexId % 2)) * 2.0)) * globalParams.lineWidth / 2.0;
    
    VertexOut vo;
    
    // Combine the point with the tangent and lineWidth to achieve a properly oriented
    // triangle for this point in the curve:
    point.x += lineWidthOffset;
    
    point = (globalParams.transform * float3(point, 1)).xy;
    vo.pos.xy = (point / globalParams.halfViewport) - float2(1,1);
    vo.pos.zw = float2(0, 1);
    vo.color = colors[chartIdx];
    vo.color.w = 1;
    
    return vo;
}

vertex VertexOut percent_fill_vertex(constant float2 *points[[buffer(0)]],
                                     constant float4 *colors[[buffer(1)]],
                                     constant GlobalParameters& globalParams[[buffer(2)]],
                                     uint vertexId [[vertex_id]])
{
    uint wtfWhy = 4;
    uint chartIdx = vertexId / (wtfWhy * globalParams.linePointsCount);
    uint pointId = vertexId / 4 + ((vertexId / 2) % 2);
    uint dataPointOffset = pointId % globalParams.linePointsCount;
    
    float allSum = 0;
    float valSum = 0;
    float prevSum = 0;
    for (uint i = 0; i < globalParams.chartCount; i++) {
        if (i == chartIdx) {
            prevSum = allSum;
        }
        
        allSum += points[dataPointOffset + i * globalParams.linePointsCount].y * colors[i].w;
        if (i == chartIdx) {
            valSum = allSum;
        }
    }
    
    float2 p1 = points[pointId];
    
    
    if (vertexId % 2 == 0) {
        p1.y = 100.0 * prevSum / allSum;
    } else {
        p1.y = 100.0 * valSum / allSum;
    }
    p1 = (globalParams.transform * float3(p1, 1)).xy;
    
    VertexOut vo;
    vo.pos.xy = (p1 / globalParams.halfViewport) - float2(1,1);
    vo.pos.zw = float2(0, 1);
    vo.color = colors[chartIdx];
    vo.color.w = 1;
    
    return vo;
}

vertex VertexOut fill_vertex(constant float2 *points[[buffer(3)]],
                             constant float4 &color[[buffer(4)]],
                             uint vertexId [[vertex_id]]) {
    VertexOut vo;
    vo.pos.xy = points[vertexId];
    vo.pos.zw = float2(0, 1);
    vo.color = color;
    return vo;
}

vertex VertexOut line_level_vertex(constant LevelIn *points[[buffer(0)]],
                                   constant GlobalParameters& globalParams[[buffer(1)]],
                                   uint vertexId [[vertex_id]])
{
    LevelIn point = points[vertexId / 4];
    float y = point.y;
    y = (globalParams.transform * float3(0.0, y, 1.0)).y;
    float x = float((vertexId / 2) % 2) * 2.0 - 1.0;
    
    // This is a little trick to avoid conditional code. We need to determine which side of the
    // triangle we are processing, so as to calculate the correct "side" of the curve, so we just
    // check for odd vs. even vertexId values to determine that:
    float lineWidthOffset = (1 - (((float) (vertexId % 2)) * 2.0)) * globalParams.lineWidth / 2.0;
    y = y + lineWidthOffset;
    
    VertexOut vo;
    vo.pos.x = x;
    vo.pos.y = y / globalParams.halfViewport[1] - 1;
    vo.pos.zw = float2(0, 1);
    vo.color = point.color;
    
    return vo;
}

fragment float4 line_fragment(VertexOut params[[stage_in]])
{
    return params.color;
}


