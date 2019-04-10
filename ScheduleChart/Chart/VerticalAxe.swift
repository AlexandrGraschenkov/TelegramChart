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
    var gridColor: Color = Color(w: 0.9, a: 1.0)
    
    
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

            var y = frame.height * CGFloat(1 - val / drawMaxVal) + frame.origin.y
            y = round(y)

            lab.frame.origin = CGPoint(x: frame.minX + inset.left - lab.frame.width,
                                       y: y - lab.frame.height)
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
        
        let val = Int64(levels[1])
        var formatter: ((Float)->(String))? = nil
        if val % 1000000 == 0 {
            formatter = {"\(Int64($0/1000000))M"}
        } else if val % 1000 == 0 {
            formatter = {"\(Int64($0/1000))K"}
        }
        
        zip(vertical, levels).forEach { (lab, val) in
            lab.valueFormatter = formatter
            lab.attachedValue = val
        }
    }
    
    private func generateValueLevels(maxVal: Float, levelsCount count: Int) -> [Float] {
        return (0..<count).map({maxVal * Float($0) / Float(count)})
    }
}
