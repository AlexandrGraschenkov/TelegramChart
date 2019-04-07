//
//  LinesDisplayBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 07/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

private extension CGAffineTransform {
    var xScale: CGFloat {
        return sqrt(a * a + c * c)
    }
    
    var yScale: CGFloat {
        return sqrt(b * b + d * d)
    }
}

class LinesDisplayBehavior: NSObject {
    typealias RangeI = ChartView.RangeI
    
    var view: ChartView
    var layers: [CAShapeLayer] = []
    var data: [ChartData] = [] {
        didSet {
            resizeShapes()
            zip(layers, data).forEach({$0.0.strokeColor = $0.1.color.cgColor})
            dataAlpha = Array(repeating: 1.0, count: data.count)
        }
    }
    var dataAlpha: [CGFloat] = [] {
        didSet {
            for (l, a) in zip(layers, dataAlpha) {
                if l.opacity != Float(a) {
                    l.opacity = Float(a)
                }
            }
        }
    }
    var transform: CGAffineTransform = .identity
    let timeDivider: CGFloat = 100_000
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect, force: Bool) {
        let newT = calculateTransform(maxValue: maxValue, displayRange: displayRange, rect: rect)
        let needUpdateData: Bool = force || significantTransformChange(t1: newT, t2: transform)
        if needUpdateData {
            // it's costly operation, data needs transfer to GPU
            updateLayersDataTransform(t: newT)
        } else {
            let dt = transform.inverted().concatenating(newT)
            updateLayersTransform(t: dt)
        }
//        updateStartEndStroke(range: displayRange)
    }
    
    
    private func resizeShapes() {
        while layers.count < data.count {
            let l = generateLayer()
            layers.append(l)
            view.layer.addSublayer(l)
        }
        while layers.count > data.count {
            let l = layers.removeLast()
            l.removeFromSuperlayer()
        }
    }
    
    private func generateLayer() -> CAShapeLayer {
        let l = ShapeLayer()
        l.lineCap = .round
        l.lineJoin = .round
        l.fillColor = nil
        l.lineWidth = view.lineWidth
        return l
    }

    
    private func calculateTransform(maxValue: Float, displayRange: RangeI, rect: CGRect) -> CGAffineTransform {
        let fromTime = CGFloat(displayRange.from)/timeDivider
        let toTime = CGFloat(displayRange.to)/timeDivider
        let maxValue = CGFloat(maxValue)
        
        var t: CGAffineTransform = .identity
        let scaleX = rect.width / (toTime - fromTime)
        t = t.translatedBy(x: rect.minX, y: rect.maxY)
        t = t.scaledBy(x: scaleX, y: -rect.height / maxValue)
        t = t.translatedBy(x: -fromTime, y: 0)
        return t
    }
    
    private func significantTransformChange(t1: CGAffineTransform, t2: CGAffineTransform) -> Bool {
        let xPercent = min(t1.xScale, t2.xScale) / max(t1.xScale, t2.xScale)
        let yPercent = min(t1.yScale, t2.yScale) / max(t1.yScale, t2.yScale)
        return xPercent < 0.8 || yPercent < 0.8
    }
    
    private func updateLayersTransform(t: CGAffineTransform) {
        let t3d = CATransform3DMakeAffineTransform(t)
        for l in layers {
            l.transform = t3d
        }
    }
    
    private func updateLayersDataTransform(t: CGAffineTransform) {
        transform = t
        
        for (l, d) in zip(layers, data) {
            let path = CGMutablePath()
            for (i, item) in d.items.enumerated() {
                let p = CGPoint(x: CGFloat(item.time) / timeDivider, y: CGFloat(item.value))
                if i == 0 {
                    path.move(to: p, transform: t)
                } else {
                    path.addLine(to: p, transform: t)
                }
            }
            l.path = path
            l.transform = CATransform3DIdentity
        }
    }
    
    private func updateStartEndStroke(range: RangeI) {
        guard let items = data.first?.items, items.count > 0 else {
            return
        }
        // unfortunately it depends on line length. If lot peaks, longer line
        // TODO: on data set we need calculate line length on each segment
        
        let rangeStart = CGFloat(range.from) / timeDivider
        let rangeEnd = CGFloat(range.to) / timeDivider
        let start = CGFloat(items.first!.time) / timeDivider
        let end = CGFloat(items.last!.time) / timeDivider
        
        var startStroke = (rangeStart - start) / (end - start)
        var endStroke = (rangeEnd - start) / (end - start)
        startStroke = max(0, min(1, startStroke))
        endStroke = max(0, min(1, endStroke))
        
        for l in layers {
            l.strokeStart = startStroke
            l.strokeEnd = endStroke
        }
    }
}
