//
//  LineDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 08/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class LineDisplay: BaseDisplay {
    
    override init(view: MetalChartView, device: MTLDevice) {
        super.init(view: view, device: device)
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "line_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    override func prepareDisplay() {
        if !dataAlphaUpdated { return }
        for i in 0..<dataAlpha.count {
            colors[i][3] = Float(dataAlpha[i])
        }
        dataAlphaUpdated = false
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        
        for i in 0..<view.chartDataCount {
            let wtfWhy = MemoryLayout<IndexType>.size
            var from = view.maxChartItemsCount * 4 * i * wtfWhy
            from += drawFrom * 4 * wtfWhy
            let count = (drawTo-drawFrom-1) * 4
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: MTLType, indexBuffer: indicesBuffer, indexBufferOffset: from)
        }
    }
}
