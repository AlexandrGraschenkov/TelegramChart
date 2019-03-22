//
//  AxesDrawer.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class VerticalAxe: NSObject {
    var show: Bool = true {
        didSet {
            if show {
                let val = maxVal
                maxVal = nil
                if val != nil {
                    setMaxVal(val!, animationDuration: 0)
                }
            } else {
                labelsPool.removeAll()
            }
        }
    }
    let view: ChartView
    var labelsPool: LabelsPool { return view.labelsPool }
    var levelsCount = 5
    var gridColor: UIColor = UIColor(white: 0.9, alpha: 1.0)
    
    
    fileprivate(set) var maxVal: Float!
    var vertical: [AttachedLabel] = []
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func setMaxVal(_ maxVal: Float, animationDuration duration: Double = 0) {
        if self.maxVal == maxVal { return }
        self.maxVal = maxVal
        if duration == 0 {
            _ = resizeVerticalIfNeeded()
            updateVerticalAttachedValues(force: true)
            vertical.forEach({ $0.alpha = 1 })
            return
        }
        
        let oldLabels = vertical
        vertical.removeAll()
        
        _ = resizeVerticalIfNeeded()
        updateVerticalAttachedValues(force: true)
        
        _ = AttachedLabelAnimator.animateAppearDismiss(appear: vertical, dismiss: oldLabels, duration: duration)
    }
    
    func drawGrid(ctx: CGContext, inset: UIEdgeInsets) {
        let drawMaxVal = view.maxValue
        
        var attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        attachedLabels.sort(by: {$0.alpha < $1.alpha})
        var prevAlpha: CGFloat = 0
        let frame = view.bounds.inset(by: UIEdgeInsets(top: inset.top, left: 0, bottom: inset.bottom, right: 0))
        for lab in attachedLabels {
            guard let val = lab.attachedValue else { continue }
            if lab.alpha == 0 { continue }
            
            if prevAlpha != lab.alpha && prevAlpha != 0 {
                ctx.setStrokeColor(gridColor.withAlphaComponent(prevAlpha).cgColor)
                ctx.strokePath()
            }
            var y = frame.height * CGFloat(1 - val / drawMaxVal) + frame.origin.y
            y = round(y)
            ctx.move(to: CGPoint(x: frame.minX, y: y))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: y))
            prevAlpha = lab.alpha
            
            lab.frame.origin = CGPoint(x: frame.minX + inset.left - lab.frame.width,
                                       y: y - lab.frame.height)
        }
        
        if prevAlpha > 0 {
            ctx.setStrokeColor(gridColor.withAlphaComponent(prevAlpha).cgColor)
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
