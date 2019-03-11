//
//  ChartView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ChartView: UIView {
    struct Range {
        var from: Float
        var to: Float
    }
    
    struct RangeI {
        var from: Int64
        var to: Int64
    }
    
    var drawGrid: Bool = true
    var showZeroYValue: Bool = true
    var lineWidth: CGFloat = 2.0
    lazy var axesDrawer: AxesDrawer = AxesDrawer(view: self)
    
    var data: [ChartData] = [] {
        didSet {
            dataMinTime = -1
            dataMaxTime = -1
            for d in data {
                if dataMinTime < 0 {
                    dataMinTime = d.items.first!.time
                    dataMaxTime = d.items.last!.time
                    continue
                }
                dataMinTime = min(dataMinTime, d.items.first!.time)
                dataMaxTime = max(dataMaxTime, d.items.last!.time)
            }
            displayRange = RangeI(from: dataMinTime, to: dataMaxTime)
        }
    }
    var dataAlpha: [Float] = []
    private(set) var dataMinTime: Int64 = -1
    private(set) var dataMaxTime: Int64 = -1
    var displayRange: RangeI = RangeI(from: 0, to: 0)
    var displayVerticalRange: Range = Range(from: 0, to: 200)
    var onDrawDebug: (()->())?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
       
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        onDrawDebug?()
        axesDrawer.drawGrid(ctx: ctx)
        
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        let chartRect = bounds.inset(by: axesDrawer.getAxesInsets())
        for (_, d) in data.enumerated() {
//            if d.alpha == 0 { continue }
            drawData(d, alpha: 1.0, ctx: ctx, from: displayRange.from, to: displayRange.to, inRect: chartRect)
        }
    }
 
    func drawData(_ data: ChartData, alpha: CGFloat, ctx: CGContext, from: Int64, to: Int64, inRect rect: CGRect) {
        guard let drawFrom = data.floorIndex(time: from),
            let drawTo = data.ceilIndex(time: to) else {
            return
        }
        let color = data.color.withAlphaComponent(alpha).cgColor
        let firstItem = data.items[drawFrom]
        let firstPoint = convertPos(time: firstItem.time, val: firstItem.value, inRect: rect)
        
        if drawFrom == drawTo {
            let circle = CGRect(x: firstPoint.x-lineWidth/2.0,
                                y: firstPoint.y-lineWidth/2.0,
                                width: lineWidth,
                                height: lineWidth)
            ctx.setFillColor(color)
            ctx.fillEllipse(in: circle)
            return
        }
        
        ctx.move(to: firstPoint)
        for i in (drawFrom+1)...drawTo {
            let item = data.items[i]
            
            let p = convertPos(time: item.time, val: item.value, inRect: rect)
            ctx.addLine(to: p)
        }
        ctx.setStrokeColor(color)
        ctx.strokePath()
    }
    
    private func convertPos(time: Int64, val: Float, inRect rect: CGRect) -> CGPoint {
        let xPercent = Float(time - displayRange.from) / Float(displayRange.to - displayRange.from)
        let x = rect.origin.x + rect.width * CGFloat(xPercent)
        let yPercent = (val - displayVerticalRange.from) / (displayVerticalRange.to - displayVerticalRange.from)
        let y = rect.maxY - rect.height * CGFloat(yPercent)
        return CGPoint(x: x, y: y)
    }

}
