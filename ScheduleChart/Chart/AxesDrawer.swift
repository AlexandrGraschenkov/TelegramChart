//
//  AxesDrawer.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class AxesDrawer: NSObject {
    var showHorisontal: Bool = true
    var showVertical: Bool = true
    let view: ChartView
    let labelsPool: LabelsPool = LabelsPool()
    let verticalWidth: CGFloat = 30
    let horisontalHeight: CGFloat = 20
    var levelsCount = 5
    
    var lastMaxVal: Float?
    var vertical: [AttachedLabel] = []
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func getAxesInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: showVertical ? verticalWidth : 0,
                            bottom: showHorisontal ? horisontalHeight : 0,
                            right: 0)
    }
    
    func drawGrid(ctx: CGContext) {
        let resized = resizeVerticalIfNeeded()
        updateVerticalAttachedValues(force: resized)
        
        var attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        attachedLabels.sort(by: {$0.alpha < $1.alpha})
        var prevAlpha: CGFloat = 0
        let frame = view.bounds.inset(by: UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: showHorisontal ? horisontalHeight : 0,
                                                       right: 0))
        let maxVal = view.displayVerticalRange.to
        for lab in attachedLabels {
            guard let val = lab.attachedValue else { continue }
            if !lab.isUsed { continue }
            if prevAlpha != lab.alpha && prevAlpha != 0 {
                ctx.setStrokeColor(UIColor(white: 0.9, alpha: prevAlpha).cgColor)
                ctx.strokePath()
            }
            var y = frame.height * CGFloat(1 - val / maxVal) + frame.origin.y
            y = round(y)
            ctx.move(to: CGPoint(x: frame.minX, y: y))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: y))
            prevAlpha = lab.alpha
            
            lab.frame.origin = CGPoint(x: frame.minX + verticalWidth - lab.frame.width,
                                       y: y - lab.frame.height)
        }
        
        if prevAlpha > 0 {
            ctx.setStrokeColor(UIColor(white: 0.9, alpha: prevAlpha).cgColor)
            ctx.strokePath()
        }
    }
    
    func resizeVerticalIfNeeded() -> Bool {
        var changed = false
        while vertical.count < levelsCount {
            let lab = labelsPool.getUnused()
            view.addSubview(lab)
            vertical.append(lab)
            changed = true
        }
        while vertical.count > levelsCount {
            let label = vertical.removeLast()
            label.removeFromSuperview()
            changed = true
        }
        return changed
    }
    
    func updateVerticalAttachedValues(force: Bool = false) {
        let update = force || lastMaxVal == view.displayVerticalRange.to
        if !update {
            return
        }
        
        lastMaxVal = view.displayVerticalRange.to
        for (idx, l) in vertical.enumerated() {
            let val = view.displayVerticalRange.to * Float(idx) / Float(vertical.count)
            l.attachedValue = val
        }
    }
}
