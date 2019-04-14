//
//  SelectionBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 14/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class SelectionDisplayBehavior: NSObject {
    
    var needShowCircles: Bool = true
    var needShowLine: Bool = true
    
    init(chart: ChartView) {
        self.chart = chart
        super.init()
    }
    
    func setChartType(_ chartType: ChartType) {
        reset()
        switch chartType {
        case .line:
            needShowCircles = true
            needShowLine = true
        case .percentage:
            needShowCircles = false
            needShowLine = true
        case .stacked:
            needShowCircles = false
            needShowLine = false
        }
    }
    
    func update(apereance: Apereance) {
        for c in selectionCircles {
            c.fillColor = apereance.bg.cgColor
        }
    }
    
    func selectDate(date: Int64, transform: CGAffineTransform) {
        if needShowLine {
            generateSelectLineIfNeeded()
            if selectionLine.isHidden {
                selectionLine.isHidden = false
            }
            var p = CGPoint(x: CGFloat(date), y: 0)
            p = p.applying(transform)
            selectionLine.center.x = p.x
        }
        
        if needShowCircles {
            showCircles(date: date, transform: transform)
        } else {
            selectionCircles.forEach({$0.removeFromSuperlayer()})
            selectionCircles = []
        }
    }
    
    func reset() {
        selectionLine?.isHidden = true
        selectionCircles.forEach({$0.removeFromSuperlayer()})
        selectionCircles = []
    }
    
    func deselect() {
        selectionLine.isHidden = true
        selectionCircles.forEach({$0.removeFromSuperlayer()})
    }
    
    private weak var chart: ChartView!
    private var selectionLine: UIView!
    private var selectionCircles: [CAShapeLayer] = []
    
    
    private func generateCircle() -> CAShapeLayer {
        let shape = ShapeLayer()
        shape.path = CGPath(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6), transform: nil)
        let fill = chart.metal.clearColor
        shape.fillColor = UIColor(red: CGFloat(fill.red),
                                  green: CGFloat(fill.green),
                                  blue: CGFloat(fill.blue),
                                  alpha: 1.0).cgColor
        shape.strokeColor = UIColor.red.cgColor
        shape.lineWidth = 2.0
        return shape
    }
    
    private func generateSelectLineIfNeeded() {
        if selectionLine != nil { return }
        let bounds = chart.bounds.inset(by: chart.chartInset)
        let y = bounds.origin.y
        let height = bounds.height
        selectionLine = UIView(frame: CGRect(x: 0, y: y, width: 2/UIScreen.main.scale, height: height))
        selectionLine.backgroundColor = UIColor(white: 0.6, alpha: 0.6)
        selectionLine.isHidden = true
        chart.addSubview(selectionLine)
    }
    
    private func generateCircles() {
        guard let data = chart.data?.data else {
            return
        }
        if selectionCircles.count == data.count { return }
        
        while selectionCircles.count < data.count {
            let c = generateCircle()
            c.strokeColor = data[selectionCircles.count].color.cgColor
            selectionCircles.append(c)
        }
    }
    
    private func showCircles(date: Int64, transform: CGAffineTransform) {
        guard let groupData = chart.data,
            let (idx, _) = groupData.getClosestDate(date: date) else {
            return
        }
        
        generateCircles()
        selectionCircles.forEach({chart.layer.addSublayer($0)})
        
//        let pixelScale = UIScreen.main.scale
        for (i, (c, d)) in zip(selectionCircles, groupData.data).enumerated() {
            let scale = i < chart.metal.customScale.count ? chart.metal.customScale[i] : 1
            let val = d.items[idx].value
            var pos: CGPoint = CGPoint(x: CGFloat(date), y: CGFloat(scale * val))
            pos = pos.applying(transform)
//            var p = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
//            p.x = round(p.x * pixelScale) / pixelScale
//            p.y = round(p.y * pixelScale) / pixelScale
            c.position = pos
        }
    }
}
