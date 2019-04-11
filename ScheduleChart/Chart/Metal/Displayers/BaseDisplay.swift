//
//  BaseDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 08/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

extension CGAffineTransform {
    func getMatrix() -> matrix_float3x3 {
        let r1 = simd_float3(Float(a) , Float(b) , 0)
        let r2 = simd_float3(Float(c) , Float(d) , 0)
        let r3 = simd_float3(Float(tx) , Float(ty) , 1)
        return matrix_float3x3(columns: (r1, r2, r3))
    }
}

typealias IndexType = UInt32
let MTLType: MTLIndexType = (MemoryLayout<IndexType>.size == 2) ? .uint16 : .uint32

class BaseDisplay: NSObject {
    typealias GroupMode = DataPreparer.GroupMode
    typealias RangeI = ChartView.RangeI
    
    var view: MetalChartView
    var chartDataCount: Int = 0
    var chartItemsCount: Int = 0
    var data: [ChartData] = [] {
        didSet { dataUpdated() }
    }
    
    var dataAlphaUpdated = false
    var dataAlpha: [CGFloat] = [] {
        didSet { dataAlphaUpdated = true }
    }
    
    let timeDivider: CGFloat = 100_000
    var groupMode: GroupMode = .none
    var showGrid: Bool = true // false for PieChart
    
    var dataReduceSwitch: [[[vector_float2]]] = []
    var currendReduceIdx: Int = -1
    let maxReduceCount: Int = 4
    var reduceSwitchOffset: CGFloat = -0.5
    var indices : [IndexType] = []
    var vertices: PageAlignedContiguousArray<vector_float2>!
    var colors: PageAlignedContiguousArray<vector_float4>!
    
    var indicesBuffer : MTLBuffer!
    var vertexBuffer : MTLBuffer!
    var colorsBuffer : MTLBuffer!
    var drawFrom: Int = 0
    var drawTo: Int = 0
    
    
    var pipelineDescriptor = MTLRenderPipelineDescriptor()
    var pipelineState : MTLRenderPipelineState! = nil
    
    init(view: MetalChartView, device: MTLDevice) {
        self.view = view
        
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
        super.init()
    }
    
    func setupBuffers(maxChartDataCount: Int, maxChartItemsCount: Int) {
        if indicesBuffer != nil && colorsBuffer.length == maxChartDataCount && vertexBuffer.length == maxChartDataCount * maxChartItemsCount {
            return
        }
        
        indices = generateIndices(chartCount: maxChartDataCount, itemsCount: maxChartItemsCount)
        indicesBuffer = (view.device.makeBuffer(bytes: indices, length: MemoryLayout<IndexType>.stride * indices.count, options: .storageModeShared))
        
        vertices = PageAlignedContiguousArray<vector_float2>(repeating: vector_float2(0, 0), count: maxChartDataCount * maxChartItemsCount)
        vertexBuffer = view.device.makeBufferWithPageAlignedArray(vertices)
        
        colors = PageAlignedContiguousArray(repeating: vector_float4(0, 0, 0, 0), count: maxChartDataCount)
        colorsBuffer = view.device.makeBufferWithPageAlignedArray(colors)
    }
    
    func generateIndices(chartCount: Int, itemsCount: Int) -> [IndexType] {
        return Array(0..<IndexType(chartCount * 4 * itemsCount))
    }
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect) {
        view.mutex.lock()
        defer { view.mutex.unlock() }
        
        let t = calculateTransform(maxValue: maxValue, displayRange: displayRange, rect: rect)
        view.globalParams.transform = t.getMatrix()
        
        // data reduce
        if data.count == 0 { return }
        let reduceCount = dataReduceSwitch.count
        let time1 = CGFloat(data[0].items.first!.time) / timeDivider
        let time2 = CGFloat(data[0].items.last!.time) / timeDivider
        let to = CGFloat(displayRange.to) / timeDivider
        let from = CGFloat(displayRange.from) / timeDivider
        let count = CGFloat(data[0].items.count)
        let displayCount = (to - from) * count / (time2 - time1)
        
        var optimalReduceIdx = log2(displayCount / rect.width) + reduceSwitchOffset
        optimalReduceIdx = max(0, optimalReduceIdx)
        if currendReduceIdx == -1 || abs(CGFloat(currendReduceIdx) - optimalReduceIdx) > 0.6 {
            let idx = min(reduceCount-1, Int(round(optimalReduceIdx)))
            setReducedData(idx: idx)
        }
        
        let fromPercent: CGFloat = (from - time1) / (time2 - time1)
        drawFrom = Int(floor(fromPercent * CGFloat(view.chartItemsCount)))
        drawFrom = max(0, drawFrom)
        
        let toPercent: CGFloat = (to - time1) / (time2 - time1)
        drawTo = Int(ceil(toPercent * CGFloat(view.chartItemsCount)))
        drawTo = min(drawTo, view.chartItemsCount)
    }
    
    func setReducedData(idx: Int) {
        print("••• SwitchReduce data", idx)
        currendReduceIdx = idx
        for (i, d) in dataReduceSwitch[idx].enumerated() {
            let vertOffset = i*view.maxChartItemsCount
            vertices.replaceSubrange(vertOffset..<vertOffset+d.count, with: d)
        }
        view.chartItemsCount = dataReduceSwitch[idx][0].count
    }
    
    func dataUpdated() {
        view.chartDataCount = data.count
        view.chartItemsCount = data.first!.items.count
        
        dataAlpha = Array(repeating: 1, count: data.count)
        dataReduceSwitch = DataPreparer.prepare(data: data, visiblePercent: dataAlpha, timeDivider: Float(timeDivider), mode: groupMode, reduceCount: maxReduceCount)
        currendReduceIdx = -1
        dataAlphaUpdated = false
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        for (i, d) in data.enumerated() {
            d.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            colors[i] = vector_float4(Float(r), Float(g), Float(b), Float(a))
        }
    }
    
    func prepareDisplay() {
        // optional
    }
    
    func display(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
    
    func calculateTransform(maxValue: Float, displayRange: RangeI, rect: CGRect) -> CGAffineTransform {
        let fromTime = CGFloat(displayRange.from)/timeDivider
        let toTime = CGFloat(displayRange.to)/timeDivider
        let maxValue = CGFloat(maxValue)
        
        var t: CGAffineTransform = .identity
        let scaleX = rect.width / (toTime - fromTime)
        t = t.scaledBy(x: UIScreen.main.scale, y: UIScreen.main.scale)
        t = t.translatedBy(x: rect.minX, y: view.bounds.height - rect.maxY)
        t = t.scaledBy(x: scaleX, y: rect.height / maxValue)
        t = t.translatedBy(x: -fromTime, y: 0)
        return t
    }
}
