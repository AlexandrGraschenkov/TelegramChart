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
    var selectedDay: Int64 = 0
    var percentFill: PercentFillDisplay!
    var pieDisplay: PieDisplay?
    
    init(percentFill: PercentFillDisplay, day: Int64, goDetail: Bool) {
        super.init(view: percentFill.view, device: percentFill.view.device, reuseBuffers: percentFill.buffers)
        
        self.percentFill = percentFill
        selectedDay = day
        groupMode = .percentage
        
        let library = percentFill.view.device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "pie_transition_vertex")
//        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "percent_fill_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "line_fragment")
        
        pipelineState = (try? percentFill.view.device.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
        
        
        let percent = getPercentage(data: percentFill.data!, dataAlpha: percentFill.dataAlpha, date: day)
        slopes = calculateLineSlops(percentage: percent, viewSize: view.drawableSize)
        
        data = percentFill.data
        dataAlpha = percentFill.dataAlpha
        drawTo = percentFill.drawTo
        drawFrom = percentFill.drawFrom
        chartDataCount = percentFill.chartDataCount
        
        if goDetail {
            runShowDetail()
        } else {
            runShowGlobal()
        }
    }
    
    func calculatePath(from: CGRect, to: CGRect, percent: CGFloat) -> CGPath {
        let corners = to.width / 2.0 * percent
        let percentFrame = CGRect(x: percent * (to.minX - from.minX) + from.minX,
                                  y: percent * (to.minY - from.minY) + from.minY,
                                  width: percent * (to.width - from.width) + from.width,
                                  height: percent * (to.height - from.height) + from.height)
        
        let p = CGMutablePath()
        p.addRect(view.bounds)
        p.addRoundedRect(in: percentFrame, cornerWidth: corners, cornerHeight: corners)
        
        return p
    }
    
    func runShowDetail() {
        let (from, to) = getFromToBounds()
        
        view.layer.addSublayer(corners)
        let color = UIColor(red: CGFloat(view.clearColor.red),
                            green: CGFloat(view.clearColor.green),
                            blue: CGFloat(view.clearColor.blue),
                            alpha: CGFloat(view.clearColor.alpha))
        corners.fillColor = color.cgColor
        corners.fillRule = .evenOdd
        corners.path = nil
        
        view.globalParams.lineWidth = 0
        
        let pie = PieDisplay(view: self.view, device: self.view.device, reuseBuffers: nil)
        guard let (_, date) = data!.getClosestDate(date: self.selectedDay) else {
            return
        }
        
        pie.range = RangeI(from: date-60, to: date+60)
        pie.data = self.data
        pie.dataAlpha = self.dataAlpha
        pie.prepare()
        
        _ = DisplayLinkAnimator.animate(duration: 0.6) { (percent) in
            let percent = -percent * (percent - 2)
            self.showGrid = percent < 0.2
            self.corners.path = self.calculatePath(from: from, to: to, percent: percent)
            self.view.globalParams.lineWidth = Float(percent)
            self.view.setNeedsDisplay()
            
            if percent == 1 {
                self.view.display = pie
            }
        }
    }
    
    func runShowGlobal() {
        let (from, to) = getFromToBounds()
        
        view.layer.addSublayer(corners)
        let color = UIColor(red: CGFloat(view.clearColor.red),
                            green: CGFloat(view.clearColor.green),
                            blue: CGFloat(view.clearColor.blue),
                            alpha: CGFloat(view.clearColor.alpha))
        corners.fillColor = color.cgColor
        corners.fillRule = .evenOdd
        corners.path = calculatePath(from: from, to: to, percent: 1)
        
        view.globalParams.lineWidth = 1
        
        _ = DisplayLinkAnimator.animate(duration: 0.6) { (percent) in
            let percent = -percent * (percent - 2)
            self.showGrid = percent < 0.2
            self.corners.path = self.calculatePath(from: from, to: to, percent: 1-percent)
            self.view.globalParams.lineWidth = 1-Float(percent)
            self.view.setNeedsDisplay()
            
            if percent == 1 {
                self.view.display = self.percentFill
            }
        }
    }
    
    func getFromToBounds() -> (CGRect, CGRect) {
        let fromBounds = view.bounds.inset(by: UIEdgeInsets(top: 70, left: 0, bottom: 30, right: 0))
        let temp = view.bounds.insetBy(dx: 40, dy: 40)
        let minSide = min(temp.width, temp.height) - 20
        let toBounds = CGRect(x: view.bounds.midX - minSide / 2,
                              y: view.bounds.midY - minSide / 2,
                              width: minSide,
                              height: minSide)
        return (fromBounds, toBounds)
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
            slope *= Float(viewSize.width / viewSize.height)
            let currAngle: Float = .pi / 2 - p * .pi - angleSum
            angleSum += p * .pi * 2
            slopes.append(SlopeAndAngle(slope: slope, angle: currAngle))
        }
        return slopes
    }
    
    
    override func onRemove() {
        super.onRemove()
        
        corners.removeFromSuperlayer()
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        super.display(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(buffers.colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&view.globalParams, length: MemoryLayout<GlobalParameters>.stride, index: 2)
        renderEncoder.setVertexBytes(slopes, length: MemoryLayout<SlopeAndAngle>.stride * slopes.count, index: 3)
        
        for i in (0..<chartDataCount).reversed() {
            if dataAlpha[i] == 0 { continue }
            
            let wtfWhy = MemoryLayout<IndexType>.size
            var from = view.maxChartItemsCount * 4 * i * wtfWhy
            from += drawFrom * 4 * wtfWhy
            let count = (drawTo-drawFrom-1) * 4
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: kIndexType, indexBuffer: buffers.triangleStripIndicesBuffer, indexBufferOffset: from)
        }
        pieDisplay?.customOnRemove()
        pieDisplay = nil
    }
}
