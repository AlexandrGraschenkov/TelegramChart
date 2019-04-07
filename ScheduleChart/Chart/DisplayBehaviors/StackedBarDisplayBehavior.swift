//
//  StackedBarDisplayBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 07/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class StackedBarDisplayBehavior: BaseDisplayBehavior {

    override var data: [ChartData] {
        didSet {
            resizeShapes()
            var stackedData: [ChartData] = []
            for (l, d) in zip(layers, data) {
                stackedData.append(d)
                l.fillColor = d.color.cgColor
                l.path = generateShape(stackedData: stackedData)
                view.layer.insertSublayer(l, at: 0)
            }
            dataAlpha = Array(repeating: 1.0, count: data.count)
        }
    }
    override var dataAlpha: [CGFloat] {
        didSet {
            for (l, a) in zip(layers, dataAlpha) {
                if l.opacity != Float(a) {
                    l.opacity = Float(a)
                }
            }
        }
    }
    var transform: CGAffineTransform = .identity
    
    override func update(maxValue: Float, displayRange: RangeI, rect: CGRect, force: Bool) {
        let t = calculateTransform(maxValue: maxValue, displayRange: displayRange, rect: rect)
        updateLayersTransform(t: t)
    }
    
    override func generateLayer() -> CAShapeLayer {
        let l = ShapeLayer()
        l.strokeColor = nil
        return l
    }
    
    private func generateShape(stackedData: [ChartData]) -> CGPath {
        let path = CGMutablePath()
        guard let d = stackedData.first, d.items.count >= 2 else {
            return path
        }
        
        let halfWidth = (d.items[1].time - d.items[0].time) / 2
        let firstP = CGPoint(x: CGFloat(d.items.first!.time - halfWidth) / timeDivider, y: 0)
        let lastP = CGPoint(x: CGFloat(d.items.last!.time + halfWidth) / timeDivider, y: 0)
        path.move(to: firstP)
        for idx in 0..<d.items.count {
            let time = d.items[idx].time
            let val: Float = stackedData.reduce(Float(0), {$0 + $1.items[idx].value})
            let p1 = CGPoint(x: CGFloat(time - halfWidth) / timeDivider, y: CGFloat(val))
            let p2 = CGPoint(x: CGFloat(time + halfWidth) / timeDivider, y: CGFloat(val))
            path.addLine(to: p1)
            path.addLine(to: p2)
        }
        path.addLine(to: lastP)
        path.closeSubpath()
        return path
    }
    
    private func updateLayersTransform(t: CGAffineTransform) {
        let t3d = CATransform3DMakeAffineTransform(t)
        for l in layers {
            l.transform = t3d
        }
    }
}
