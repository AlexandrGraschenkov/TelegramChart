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
    
    fileprivate(set) var maxVal: Float!
    var vertical: [AttachedLabel] = []
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func setMaxVal(_ maxVal: Float, animationDuration duration: Double = 0) {
        if self.maxVal == maxVal { return }
        if duration == 0 {
            _ = resizeVerticalIfNeeded()
            self.maxVal = maxVal
            updateVerticalAttachedValues(force: true)
            vertical.forEach({ $0.alpha = 1 })
            return
        }
        
        let oldLabels = vertical
        let startAlpha = vertical.first?.alpha ?? 1
        vertical.removeAll()
        
        _ = resizeVerticalIfNeeded()
        self.maxVal = maxVal
        updateVerticalAttachedValues(force: true)
        
        let minAlpha: CGFloat = 0.01
        let startAppear: CGFloat = 0.0
        let appearDur: CGFloat = 0.8
        let startDismiss: CGFloat = 0.0
        let dismissDur: CGFloat = 0.5
        
        vertical.forEach({ $0.alpha = minAlpha })
        _ = DisplayLinkAnimator.animate(duration: duration) { (progress) in
            if maxVal == self.maxVal {
                let val = (progress - startAppear) / appearDur
                let alpha: CGFloat = min(1, max(minAlpha, val))
                self.vertical.forEach({$0.alpha = alpha})
            }
            
            let val = (progress - startDismiss) / dismissDur
            let alpha: CGFloat = max(0, min(1, startAlpha-val))
            oldLabels.forEach({$0.alpha = alpha})
        }
    }
    
    func getAxesInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: showVertical ? verticalWidth : 0,
                            bottom: showHorisontal ? horisontalHeight : 0,
                            right: 0)
    }
    
    func drawGrid(ctx: CGContext) {
        let drawMaxVal = view.displayVerticalRange.to
        
        var attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        attachedLabels.sort(by: {$0.alpha < $1.alpha})
        var prevAlpha: CGFloat = 0
        let frame = view.bounds.inset(by: UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: showHorisontal ? horisontalHeight : 0,
                                                       right: 0))
        for lab in attachedLabels {
            guard let val = lab.attachedValue else { continue }
            if lab.unused {
                continue
            }
            if prevAlpha != lab.alpha && prevAlpha != 0 {
                ctx.setStrokeColor(UIColor(white: 0.9, alpha: prevAlpha).cgColor)
                ctx.strokePath()
            }
            var y = frame.height * CGFloat(1 - val / drawMaxVal) + frame.origin.y
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
    
    private func resizeVerticalIfNeeded() -> Bool {
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
    
    private func updateVerticalAttachedValues(force: Bool = false) {
        let update = force
        if !update {
            return
        }
        
        let levels = generateValueLevels(maxVal: maxVal, levelsCount: vertical.count)
        zip(vertical, levels).forEach { (lab, val) in
            lab.attachedValue = val
        }
    }
    
    private func generateValueLevels(maxVal: Float, levelsCount count: Int) -> [Float] {
        return (0..<count).map({maxVal * Float($0) / Float(count)})
    }
}
