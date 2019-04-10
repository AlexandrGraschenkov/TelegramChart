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

    private var dataAlphaUpdated = false
    override var dataAlpha: [CGFloat] {
        didSet { dataAlphaUpdated = true }
    }
    
    override init(view: MetalChartView, device: MTLDevice) {
        super.init(view: view, device: device)
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "line_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    override func dataUpdated() {
        view.chartDataCount = data.count
        view.chartItemsCount = data.first!.items.count
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        for (i, d) in data.enumerated() {
            d.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            view.colors[i] = vector_float4(Float(r), Float(g), Float(b), Float(a))
            
            let vertOffset = i*view.maxChartItemsCount
            for (ii, item) in d.items.enumerated() {
                view.vertices[vertOffset + ii] = vector_float2(Float(item.time) / Float(timeDivider), Float(item.value))
            }
        }
    }
    
    override func prepareDisplay() {
        if !dataAlphaUpdated { return }
        for i in 0..<dataAlpha.count {
            view.colors[i][3] = Float(dataAlpha[i])
        }
        print(dataAlpha)
        dataAlphaUpdated = false
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(view.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(view.colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        
        for i in 0..<view.chartDataCount {
            let wtfWhy = 2
            let from = view.maxChartItemsCount * 4 * i * wtfWhy
            let count = (view.chartItemsCount-1) * 4
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: .uint16, indexBuffer: view.indicesBuffer!, indexBufferOffset: from)
        }
    }
}
