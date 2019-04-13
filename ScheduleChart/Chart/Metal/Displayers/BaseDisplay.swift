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
let kIndexType: MTLIndexType = (MemoryLayout<IndexType>.size == 2) ? .uint16 : .uint32

class BaseDisplay: NSObject {
    typealias GroupMode = DataPreparer.GroupMode
    typealias RangeI = ChartView.RangeI
    enum IndexDrawType {
        case triangle
        case triangleStrip
    }
    
    var view: MetalChartView
    var data: ChartGroupData? {
        didSet { dataUpdated() }
    }
    var chartDataCount: Int = 0
    var chartItemsCount: Int = 0
    
    var dataAlphaUpdated = false
    var dataAlpha: [CGFloat] = [] {
        didSet { dataAlphaUpdated = true }
    }
    
    let timeDivider: Float = 100_000
    var groupMode: GroupMode = .none
    var indexType: IndexDrawType = .triangleStrip
    var showGrid: Bool = true // false for PieChart
    
    var dataReduceSwitch: [[[vector_float2]]] = []
    var currendReduceIdx: Int = -1
    let maxReduceCount: Int = 1
    var reduceSwitchOffset: Float = -0.5
    
    var buffers: MetalBuffer!
    var drawFrom: Int = 0
    var drawTo: Int = 0
    var selectionDate: Int64?
    
    
    
    var pipelineDescriptor = MTLRenderPipelineDescriptor()
    var pipelineState : MTLRenderPipelineState! = nil
    
    init(view: MetalChartView, device: MTLDevice, reuseBuffers: MetalBuffer?) {
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
        
        buffers = reuseBuffers
        super.init()
    }
    
    
    func setupBuffers(maxChartDataCount: Int, maxChartItemsCount: Int) {
        if buffers == nil {
            buffers = MetalBuffer(device: view.device)
        }
        let strip = (indexType == .triangleStrip)
        buffers.setup(maxDataCount: maxChartDataCount, maxItemsCount: maxChartItemsCount, triangleStrip: strip)
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
        guard let groupData = data, groupData.data.count > 0 else { return }
        
        let reduceCount = dataReduceSwitch.count
        let minTime = Float(groupData.getMinTime()) / timeDivider
        let maxTime = Float(groupData.getMaxTime()) / timeDivider
        let to = Float(displayRange.to) / timeDivider
        let from = Float(displayRange.from) / timeDivider
        let count = Float(groupData.itemsCount)
        let displayCount = (to - from) * count / (maxTime - minTime)
        
        var optimalReduceIdx = log2(displayCount / Float(rect.width)) + reduceSwitchOffset
        optimalReduceIdx = max(0, optimalReduceIdx)
        if currendReduceIdx == -1 || abs(Float(currendReduceIdx) - optimalReduceIdx) > 0.6 {
            let idx = min(reduceCount-1, Int(round(optimalReduceIdx)))
            setReducedData(idx: idx)
        }
        
        let fromPercent: Float = (from - minTime) / (maxTime - minTime)
        drawFrom = Int(floor(fromPercent * Float(chartItemsCount)))
        drawFrom = max(0, drawFrom-1)
        
        let toPercent: Float = (to - minTime) / (maxTime - minTime)
        drawTo = Int(ceil(toPercent * Float(chartItemsCount)))
        drawTo = min(drawTo+1, chartItemsCount)
    }
    
    func setReducedData(idx: Int) {
//        print("••• SwitchReduce data", idx)
        currendReduceIdx = idx
        for (i, d) in dataReduceSwitch[idx].enumerated() {
            let vertOffset = i*view.maxChartItemsCount
            buffers.vertices.replaceSubrange(vertOffset..<vertOffset+d.count, with: d)
        }
        chartItemsCount = dataReduceSwitch[idx][0].count
    }
    
    func dataUpdated() {
        guard let groupData = data, groupData.data.count > 0 else {
            chartDataCount = 0
            chartItemsCount = 0
            return
        }
        
        view.globalParams.chartCount = UInt32(groupData.data.count)
        chartDataCount = groupData.data.count
        chartItemsCount = groupData.itemsCount
        
        dataAlpha = groupData.data.map({$0.visible ? CGFloat(1.0) : CGFloat(0.0)})
        dataReduceSwitch = groupData.preparedData.data
        currendReduceIdx = -1
        dataAlphaUpdated = false
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        for (i, d) in groupData.data.enumerated() {
            d.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            buffers.colors[i] = vector_float4(Float(r), Float(g), Float(b), Float(a))
        }
    }
    
    func setSelectionDate(date: Int64?) {
        selectionDate = date
    }
    
    // MARK: - display
    func prepareDisplay() {
        if !dataAlphaUpdated { return }
        for i in 0..<dataAlpha.count {
            buffers.colors[i][3] = Float(dataAlpha[i])
        }
        dataAlphaUpdated = false
    }
    
    func display(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
    
    func calculateTransform(maxValue: Float, displayRange: RangeI, rect: CGRect) -> CGAffineTransform {
        let fromTime = CGFloat(displayRange.from)/CGFloat(timeDivider)
        let toTime = CGFloat(displayRange.to)/CGFloat(timeDivider)
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
