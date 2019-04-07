//
//  BaseDisplayBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 07/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class BaseDisplayBehavior: NSObject {
    enum DataGroping {
        case none, stacked, percentage
    }
    
    typealias RangeI = ChartView.RangeI
    var view: ChartView
    var layers: [CAShapeLayer] = []
    var data: [ChartData] = []
    var dataAlpha: [CGFloat] = []
    let timeDivider: CGFloat = 100_000
    var grooping: DataGroping = .none
    var showGrid: Bool = true // false for PieChart
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect, force: Bool) {
        
    }
    
    func calculateTransform(maxValue: Float, displayRange: RangeI, rect: CGRect) -> CGAffineTransform {
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
    
    
    func resizeShapes() {
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
    
    func generateLayer() -> CAShapeLayer {
        let l = ShapeLayer()
        return l
    }
}
