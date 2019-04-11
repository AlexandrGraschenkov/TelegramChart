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
    private let fixDrawSpacing: Float = 1.004
    
    override init(view: MetalChartView, device: MTLDevice) {
        super.init(view: view, device: device)
        
        reduceSwitchOffset = -0.2
        groupMode = .stacked
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "stacked_fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    override func setReducedData(idx: Int) {
        super.setReducedData(idx: idx)
        let data = dataReduceSwitch[currendReduceIdx]
        let dt = data[0][1][0] - data[0][0][0]
        view.globalParams.lineWidth = fixDrawSpacing * Float(dt)
    }
    
    override func generateIndices(chartCount: Int, itemsCount: Int) -> [IndexType] {
        var result: [IndexType] = []
        result.reserveCapacity(chartCount * itemsCount * 6)
        for i in  0..<itemsCount*chartCount {
            let offset = IndexType(i*4)
            result.append(contentsOf: [offset, offset + 1, offset + 2,
                                       offset + 1, offset + 2, offset + 3])
        }
        return result
    }
    
    override func dataUpdated() {
        super.dataUpdated()
        let dt = data[0].items[1].time - data[0].items[0].time
        view.globalParams.lineWidth = fixDrawSpacing * (Float(dt) / Float(timeDivider))
    }
    
    override func prepareDisplay() {
        if !dataAlphaUpdated || currendReduceIdx < 0 { return }
        dataAlphaUpdated = false
        
        dataReduceSwitch = DataPreparer.prepare(data: data, visiblePercent: dataAlpha, timeDivider: Float(timeDivider), mode: groupMode, reduceCount: maxReduceCount)
        setReducedData(idx: currendReduceIdx)
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        
        for i in (0..<view.chartDataCount).reversed() {
            let wtfWhy = MemoryLayout<IndexType>.size
            var from = view.maxChartItemsCount * 6 * i * wtfWhy
            from += drawFrom * 6 * wtfWhy
            let count = (drawTo-drawFrom) * 6
            
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: count, indexType: MTLType, indexBuffer: indicesBuffer, indexBufferOffset: from)
        }
    }

}
