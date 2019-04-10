//
//  LineLevelDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 09/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

struct LineAlpha {
    var y: Float
    var color: vector_float4
}

class LineLevelDisplay: BaseDisplay {
    
    private var lines: PageAlignedContiguousArray<LineAlpha>!
    private var linesBuffer: MTLBuffer!
    private let maxLinesCount = 16
    private var indicesBuffer: MTLBuffer!
    private var linesCount: Int = 0
    
    override init(view: MetalChartView, device: MTLDevice) {
        super.init(view: view, device: device)
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "line_level_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
    }
    
    func update(lines: [LineAlpha]) {
        var lines = lines
        if lines.count > maxLinesCount {
            lines.sort(by: {$0.color[3] < $1.color[3]})
            while lines.count > maxLinesCount {
                lines.removeLast()
            }
        }
        if self.lines == nil {
            self.lines = PageAlignedContiguousArray<LineAlpha>(repeating: LineAlpha(y: 0, color: vector_float4(0, 0, 0, 0)), count: maxLinesCount)
            linesBuffer = view.device.makeBufferWithPageAlignedArray(self.lines)
            
            var indices: [UInt16] = []
            for i in 0..<maxLinesCount {
                let ii = UInt16(i * 4)
                // 2 triangle
                indices.append(contentsOf: [ii, ii+1, ii+2,
                                            ii+1, ii+2, ii+3])
            }
            indicesBuffer = view.device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: .storageModeShared)
        }
        for (idx, l) in lines.enumerated() {
            self.lines[idx] = l
        }
        linesCount = lines.count
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        if lines == nil { return }
        if linesCount == 0 { return }
        
        super.display(renderEncoder: renderEncoder)
        
        var global = view.globalParams!
        global.lineWidth = 2.0
        renderEncoder.setVertexBuffer(linesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&global, length: MemoryLayout<GlobalParameters>.stride, index: 1)
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: linesCount*6, indexType: .uint16, indexBuffer: indicesBuffer, indexBufferOffset: 0)
    }
}
