//
//  StackFillDisplaySelection.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 11/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class StackFillDisplaySelection: NSObject {

    init(view: MetalChartView) {
        self.view = view
        super.init()
        setup()
    }
    
    let view: MetalChartView
    var pipelineDescriptor = MTLRenderPipelineDescriptor()
    var pipelineState : MTLRenderPipelineState! = nil
    var vertices: [vector_float2] = Array(repeating: vector_float2(0, 0), count: 8)
    
    private func setup() {
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // Run with 4x MSAA:
        pipelineDescriptor.sampleCount = 4
        
        let library = view.device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? view.device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
        
        vertices[0] = vector_float2(-1, -1)
        vertices[1] = vector_float2(-1, 1)
        vertices[6] = vector_float2(1, -1)
        vertices[7] = vector_float2(1, 1)
    }
    
    func updateVertices(time: Float, width: Float) {
        let t = view.globalParams.transform
        
        var left = matrix_multiply(t, vector_float3(time-width/2.0, 0, 1))[0]
        left = left / view.globalParams.halfViewport.0 - 1
        vertices[2] = vector_float2(left, -1)
        vertices[3] = vector_float2(left, 1)
        
        var right = matrix_multiply(t, vector_float3(time+width/2.0, 0, 1))[0]
        right = right / view.globalParams.halfViewport.0 - 1
        vertices[4] = vector_float2(right, -1)
        vertices[5] = vector_float2(right, 1)
    }
    
    func drawSelection(renderEncoder: MTLRenderCommandEncoder, time: Float, width: Float, reuseTriangleIndexes: MTLBuffer) {
        updateVertices(time: time, width: width)
        var color = vector_float4(Float(view.clearColor.red),
                                  Float(view.clearColor.green),
                                  Float(view.clearColor.blue),
                                  0.5)
        
        // draw
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<vector_float2>.stride * vertices.count, index: 3)
        renderEncoder.setVertexBytes(&color, length: MemoryLayout<vector_float4>.stride, index: 4)
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 12, indexType: MTLType, indexBuffer: reuseTriangleIndexes, indexBufferOffset: 0)
    }
}
