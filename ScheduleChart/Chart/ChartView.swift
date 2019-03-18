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
    lazy var verticalAxe: VerticalAxe = VerticalAxe(view: self)
    lazy var horisontalAxe: HorisontalAxe = HorisontalAxe(view: self)
    
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
    var maxValAnimatorCancel: Cancelable?
    var rangeAnimatorCancel: Cancelable?
    var chartInset = UIEdgeInsets(top: 0, left: 40, bottom: 30, right: 30)
    
    func animateMaxVal(val: Float) {
        let duration: Double = 0.5
        let fromVal = displayVerticalRange.to
        maxValAnimatorCancel?()
        maxValAnimatorCancel = DisplayLinkAnimator.animate(duration: duration) { (percent) in
            self.displayVerticalRange.to = (val - fromVal) * Float(percent) + fromVal
            self.setNeedsDisplay()
        }
        verticalAxe.setMaxVal(val, animationDuration: duration)
    }
    
    func setRange(minTime: Int64, maxTime: Int64, animated: Bool) {
        rangeAnimatorCancel?()
        if !animated {
            displayRange.from = minTime
            displayRange.to = maxTime
            setNeedsDisplay()
            horisontalAxe.setRange(minTime: displayRange.from, maxTime: displayRange.to, animationDuration: 0)
            // TODO
            return
        }
        
        let fromRange = displayRange
        rangeAnimatorCancel = DisplayLinkAnimator.animate(duration: 0.5, closure: { (percent) in
            self.displayRange.from = Int64(CGFloat(minTime - fromRange.from) * percent) + fromRange.from
            self.displayRange.to = Int64(CGFloat(maxTime - fromRange.to) * percent) + fromRange.to
            self.setNeedsDisplay()
            if percent == 1 {
                self.rangeAnimatorCancel = nil
            }
        })
        
        horisontalAxe.setRange(minTime: minTime, maxTime: maxTime, animationDuration: 0.5)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
       
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        onDrawDebug?()
        if verticalAxe.maxVal == nil {
            verticalAxe.setMaxVal(displayVerticalRange.to)
        }
        verticalAxe.drawGrid(ctx: ctx, inset: chartInset)
        if horisontalAxe.maxTime == 0 && data.count > 0 {
            horisontalAxe.setRange(minTime: displayRange.from, maxTime: displayRange.to)
        }
        if rangeAnimatorCancel != nil {
            horisontalAxe.layoutLabels()
        }
//        if horisontalAxe.minTime != displayRange.from || horisontalAxe.maxTime != displayRange.to {
//            horisontalAxe.setRange(minTime: displayRange.from, maxTime: displayRange.to, animationDuration: 0.5)
//        }
        
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        let chartRect = bounds.inset(by: chartInset)
//        ctx.clip(to: chartRect)
        for (_, d) in data.enumerated() {
//            if d.alpha == 0 { continue }
            drawData(d, alpha: 1.0, ctx: ctx, from: displayRange.from, to: displayRange.to, inRect: chartRect)
        }
//        ctx.resetClip()
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
