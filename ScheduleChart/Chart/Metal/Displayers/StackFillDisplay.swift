//
//  FillDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 08/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class StackFillDisplay: BaseDisplay {
    
    override init(view: MetalChartView, device: MTLDevice) {
        super.init(view: view, device: device)
        
        self.grouping = .stacked
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "stacked_fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    override func generateIndices(chartCount: Int, itemsCount: Int) -> [UInt16] {
        var result: [UInt16] = []
        result.reserveCapacity(chartCount * itemsCount * 6)
        for i in  0..<itemsCount*chartCount {
            let offset = UInt16(i*4)
            result.append(contentsOf: [offset, offset + 1, offset + 2,
                                       offset + 1, offset + 2, offset + 3])
        }
        return result
    }
    
    override func dataUpdated() {
        view.chartDataCount = data.count
        view.chartItemsCount = data.first!.items.count
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        for (i, d) in data.enumerated() {
            d.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            colors[i] = vector_float4(Float(r), Float(g), Float(b), Float(a))
            
            let vertOffset = i*view.maxChartItemsCount
            for (ii, item) in d.items.enumerated() {
                vertices[vertOffset + ii] = vector_float2(Float(item.time) / Float(timeDivider), Float(item.value))
            }
        }
        let dt = data[0].items[1].time - data[0].items[0].time
        let fixDrawSpacing: Float = 1.0015
        view.globalParams.lineWidth = fixDrawSpacing * (Float(dt) / Float(timeDivider))
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        
        for i in 0..<view.chartDataCount {
            let wtfWhy = 2
            let from = view.maxChartItemsCount * 6 * i * wtfWhy
            let count = view.chartItemsCount * 6
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: count, indexType: .uint16, indexBuffer: indicesBuffer, indexBufferOffset: from)
        }
    }

}
