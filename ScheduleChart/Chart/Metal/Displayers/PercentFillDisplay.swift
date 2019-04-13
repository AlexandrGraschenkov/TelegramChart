//
//  PercentFillDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 11/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class PercentFillDisplay: BaseDisplay {
    
    override init(view: MetalChartView, device: MTLDevice, reuseBuffers: MetalBuffer?) {
        super.init(view: view, device: device, reuseBuffers: reuseBuffers)
        
        reduceSwitchOffset = -0.2
        groupMode = .percentage
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "percent_fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(buffers.colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        
        for i in (0..<chartDataCount).reversed() {
            let wtfWhy = MemoryLayout<IndexType>.size
            var from = view.maxChartItemsCount * 4 * i * wtfWhy
            from += drawFrom * 4 * wtfWhy
            let count = (drawTo-drawFrom-1) * 4
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: kIndexType, indexBuffer: buffers.triangleStripIndicesBuffer, indexBufferOffset: from)
        }
    }
    
}
