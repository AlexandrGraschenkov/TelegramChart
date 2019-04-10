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

class BaseDisplay: NSObject {
    enum DataGrouping {
        case none, stacked, percentage
    }
    
    typealias RangeI = ChartView.RangeI
    var view: MetalChartView
    var chartDataCount: Int = 0
    var chartItemsCount: Int = 0
    var data: [ChartData] = [] {
        didSet { dataUpdated() }
    }
    var dataAlpha: [CGFloat] = []
    let timeDivider: CGFloat = 100_000
    var grouping: DataGrouping = .none
    var showGrid: Bool = true // false for PieChart
    
    var indices : [UInt16] = []
    var vertices: PageAlignedContiguousArray<vector_float2>!
    var colors: PageAlignedContiguousArray<vector_float4>!
    
    var indicesBuffer : MTLBuffer!
    var vertexBuffer : MTLBuffer!
    var colorsBuffer : MTLBuffer!
    
    
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
        
        let totalCount: Int = maxChartItemsCount * 4 * maxChartDataCount
        indices = generateIndices(chartCount: maxChartDataCount, itemsCount: maxChartItemsCount)
        indicesBuffer = (view.device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: .storageModeShared))
        
        vertices = PageAlignedContiguousArray<vector_float2>(repeating: vector_float2(0, 0), count: maxChartDataCount * maxChartItemsCount)
        vertexBuffer = view.device.makeBufferWithPageAlignedArray(vertices)
        
        colors = PageAlignedContiguousArray(repeating: vector_float4(0, 0, 0, 0), count: maxChartDataCount)
        colorsBuffer = view.device.makeBufferWithPageAlignedArray(colors)
    }
    
    func generateIndices(chartCount: Int, itemsCount: Int) -> [UInt16] {
        return Array(0..<UInt16(chartCount * 4 * itemsCount))
    }
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect) {
        let t = calculateTransform(maxValue: maxValue, displayRange: displayRange, rect: rect)
        view.globalParams.transform = t.getMatrix()
    }
    
    func dataUpdated() {
        assert(false, "override it")
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
