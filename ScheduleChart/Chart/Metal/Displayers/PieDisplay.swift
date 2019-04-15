//
//  PieDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 15/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class PieDisplay: BaseDisplay {

    var shapes: [CAShapeLayer] = []
    var range: RangeI = RangeI(from: 0, to: 0)
    
    override init(view: MetalChartView, device: MTLDevice, reuseBuffers: MetalBuffer?) {
        super.init(view: view, device: device, reuseBuffers: nil)
        showGrid = false
    }
    
    override func dataUpdated() {
        shapes.forEach({$0.removeFromSuperlayer()})
    }
    
    override func prepareDisplay() {
        guard let data = data else { return }
        if data.data.count == shapes.count { return }
        
        for d in data.data {
            let s = ShapeLayer()
            s.fillColor = d.color.cgColor
            shapes.append(s)
            view.layer.addSublayer(s)
        }
    }
    
    func prepare() {
        DispatchQueue.global().async {
            self.prepareDisplay()
            for s in self.shapes {
                s.isHidden = true
            }
            self.updateShapes()
        }
    }
    
    override func update(minValue: Float, maxValue: Float, displayRange: BaseDisplay.RangeI, rect: CGRect) {
        range = displayRange

    }
    
    func getCircleFrame() -> CGRect {
        let temp = view.bounds.insetBy(dx: 40, dy: 40)
        let minSide = min(temp.width, temp.height) - 20
        let toBounds = CGRect(x: view.bounds.midX - minSide / 2,
                              y: view.bounds.midY - minSide / 2,
                              width: minSide,
                              height: minSide)
        
        return toBounds
    }
    
    func getPercentage() -> [CGFloat] {
        guard let data = data else { return [] }
        
        var (start, _) = data.getClosestDate(date: range.from, mode: .ceil) ?? (0, 0)
        var (end, _) = data.getClosestDate(date: range.to, mode: .floor) ?? (0, 0)
        if start > end {
            swap(&start, &end) // TODO: bad bad code
            //
        }
        var sum = Array(repeating: Float(0), count: data.data.count)
        for ii in start...end {
            for i in 0..<data.data.count {
                if dataAlpha[i] == 0 { continue }
                sum[i] += data.data[i].items[ii].value
            }
        }
        for i in 0..<sum.count {
            sum[i] = sum[i] * Float(dataAlpha[i])
        }
        let total = sum.reduce(0, +)
        for i in 0..<sum.count {
            sum[i] = sum[i] / total
        }
        return sum.map{CGFloat($0)}
    }
    
    func updateShapes() {
        let perc = getPercentage()
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        let radius = getCircleFrame().width / 2.0
        var startAngle: CGFloat = 0
        for (idx, s) in shapes.enumerated() {
            let alpha = dataAlpha[idx]
            if alpha == 0 {
                s.path = nil
                continue
            }
            
            let endAngle = startAngle + perc[idx] * .pi * 2
            let start = CGPoint(x: center.x + radius*cos(startAngle), y: center.y + radius*sin(startAngle))
            
            let path = CGMutablePath()
            path.move(to: center)
            path.addLine(to: start)
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.closeSubpath()
            
            s.path = path
            startAngle = endAngle
        }
    }
    
    func customOnRemove() {
        shapes.forEach({$0.removeFromSuperlayer()})
        shapes = []
    }
    
    override func display(renderEncoder: MTLRenderCommandEncoder) {
        for s in shapes {
            s.isHidden = false
        }
        updateShapes()
    }
}
