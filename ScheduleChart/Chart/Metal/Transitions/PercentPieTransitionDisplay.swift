//
//  PercentPieTransitionDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 15/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

struct SlopeAndAngle {
    var slope: Float
    var angle: Float
}

class PercentPieTransitionDisplay: BaseDisplay {

    var slopes: [SlopeAndAngle] = []
    var corners: CAShapeLayer = ShapeLayer()
    
    init(percentFill: PercentFillDisplay, day: Int64) {
        super.init(view: percentFill.view, device: percentFill.view.device, reuseBuffers: percentFill.buffers)
        
        groupMode = .percentage
        
        let library = percentFill.view.device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "pie_transition_vertex")
//        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "percent_fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? percentFill.view.device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
        
        let percent = getPercentage(data: percentFill.data!, dataAlpha: percentFill.dataAlpha, date: day)
        slopes = calculateLineSlops(percentage: percent, viewSize: view.drawableSize)
        
        dataAlpha = percentFill.dataAlpha
        drawTo = percentFill.drawTo
        drawFrom = percentFill.drawFrom
        chartDataCount = percentFill.chartDataCount
        
        runAnim()
    }
    
    func calculatePath(from: CGRect, to: CGRect, percent: CGFloat) -> CGPath {
        let corners = to.width / 2.0 * percent
        let percentFrame = CGRect(x: percent * (to.minX - from.minX) + from.minX,
                                  y: percent * (to.minY - from.minY) + from.minY,
                                  width: percent * (to.width - from.width) + from.width,
                                  height: percent * (to.height - from.height) + from.height)
        
        let p = CGMutablePath()
        p.addRect(from)
        p.addRoundedRect(in: percentFrame, cornerWidth: corners, cornerHeight: corners)
        
        return p
    }
    
    func runAnim() {
        let fromBounds = view.bounds
        let temp = view.bounds.insetBy(dx: 30, dy: 20)
        let minSide = min(temp.width, temp.height) - 20
        let toBounds = CGRect(x: view.bounds.midX - minSide / 2,
                              y: view.bounds.midY - minSide / 2,
                              width: minSide,
                              height: minSide)
        
        view.layer.addSublayer(corners)
        corners.fillColor = UIColor(white: 1, alpha: 1).cgColor
        corners.fillRule = .evenOdd
        
        view.globalParams.lineWidth = 0
        _ = DisplayLinkAnimator.animate(duration: 0.4) { (percent) in
//            let percent = -percent * (percent - 2)
            self.showGrid = percent < 0.2
            self.corners.path = self.calculatePath(from: fromBounds, to: toBounds, percent: percent)
            self.view.globalParams.lineWidth = Float(percent)
            self.view.setNeedsDisplay()
        }
    }
    
    
    func getPercentage(data: ChartGroupData, dataAlpha: [CGFloat], date: Int64) -> [Float] {
        guard let (idx,_) = data.getClosestDate(date: date) else {
            return []
        }
        
        var percentages: [Float] = []
        var sumPercentages: Float = 0
        for i in 0..<dataAlpha.count {
            let val = data.data[i].items[idx].value
            percentages.append(val)
            sumPercentages += val
        }
        percentages = percentages.map{$0 / sumPercentages}
        return percentages
    }
    
    func calculateLineSlops(percentage: [Float], viewSize: CGSize) -> [SlopeAndAngle] {
        var slopes: [SlopeAndAngle] = []
        var angleSum: Float = 0
        for p in percentage {
            let angle = .pi / 2.0 - p * .pi
            var slope = tan(angle)
//            slope /= Float(viewSize.width / viewSize.height)
            let currAngle: Float = .pi / 2 - p * .pi - angleSum
            angleSum += p * .pi * 2
            slopes.append(SlopeAndAngle(slope: slope, angle: currAngle))
        }
        return slopes
    }
    
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(buffers.colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        renderEncoder.setVertexBytes(slopes, length: MemoryLayout<SlopeAndAngle>.stride * slopes.count, index: 3)
        
        for i in (0..<chartDataCount).reversed() {
//        for i in (3..<4).reversed() {
            if dataAlpha[i] == 0 { continue }
            
            let wtfWhy = MemoryLayout<IndexType>.size
            var from = view.maxChartItemsCount * 4 * i * wtfWhy
            from += drawFrom * 4 * wtfWhy
            let count = (drawTo-drawFrom-1) * 4
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: kIndexType, indexBuffer: buffers.triangleStripIndicesBuffer, indexBufferOffset: from)
        }
    }
}
