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
    
    fileprivate(set) var maxVal: Float!
    var vertical: [AttachedLabel] = []
    var verticalRight: [AttachedLabel] = []
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    func setMaxVal(_ maxVal: Float, animationDuration duration: Double = 0) {
        if self.maxVal == maxVal { return }
        self.maxVal = maxVal
        if duration == 0 {
            _ = resizeVerticalIfNeeded()
            _ = resizeVerticalRightIfNeeded()
            updateVerticalAttachedValues()
            vertical.forEach({ $0.alpha = 1 })
            verticalRight.forEach({ $0.alpha = 1 })
            return
        }
        
        let oldLabels = vertical
        vertical.removeAll()
        let oldRightLabels = verticalRight
        verticalRight.removeAll()
        
        _ = resizeVerticalIfNeeded()
        _ = resizeVerticalRightIfNeeded()
        updateVerticalAttachedValues()
        
        _ = AttachedLabelAnimator.animateAppearDismiss(appear: vertical+verticalRight, dismiss: oldLabels+oldRightLabels, duration: duration)
    }
    
    func updateLabelsPos(inset: UIEdgeInsets) {
        let drawMaxVal = view.maxValue

        let attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        let frame = view.bounds.inset(by: UIEdgeInsets(top: inset.top, left: 0, bottom: inset.bottom, right: 0))
        for lab in attachedLabels {
            guard let val = lab.attachedValue else { continue }
            if lab.alpha == 0 { continue }

            var y = frame.height * CGFloat(1 - val / drawMaxVal) + frame.origin.y
            y = round(y)

            let x: CGFloat
            if lab.rightAligment {
                x = frame.maxX - inset.right
            } else {
                x = frame.minX + inset.left - lab.frame.width
            }
            lab.frame.origin = CGPoint(x: x,
                                       y: y - lab.frame.height)
        }
    }
    
    func resetRightLabels() {
        
    }
    
    func setupRightLabels(rightScale: Float, leftColor: UIColor, rightColor: UIColor) {
        self.rightScale = rightScale
        self.leftColor = leftColor
        self.rightColor = rightColor
    }
    
    
    // mark: - private
    private var rightScale: Float?
    private var leftColor: UIColor?
    private var rightColor: UIColor?
    private func resizeVerticalIfNeeded() -> Bool {
        var changed = false
        while vertical.count < levelsCount {
            let lab = labelsPool.getUnused()
            lab.customColor = leftColor
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
    private func resizeVerticalRightIfNeeded() -> Bool {
        var changed = false
        let count = rightScale == nil ? 0 : levelsCount
        
        while verticalRight.count < count {
            let lab = labelsPool.getUnused()
            lab.rightAligment = true
            lab.customColor = rightColor
            view.addSubview(lab)
            verticalRight.append(lab)
            changed = true
        }
        while verticalRight.count > count {
            let label = verticalRight.removeLast()
            label.removeFromSuperview()
            changed = true
        }
        return changed
    }
    
    private func updateVerticalAttachedValues() {
        
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
        if let scale = rightScale {
            updateRightVerticalAttachedValues(scale: scale)
        }
    }
    
    private func updateRightVerticalAttachedValues(scale: Float) {
        var levels = generateValueLevels(maxVal: maxVal, levelsCount: verticalRight.count)
        
        let val = Int64(levels[1] / scale)
        var formatter: ((Float)->(String))? = {"\(Int64($0 / scale))"}
        if val % 1000000 == 0 {
            formatter = {"\(Int64($0 / scale / 1000000))M"}
        } else if val % 1000 == 0 {
            formatter = {"\(Int64($0 / scale / 1000))K"}
        }
        
        zip(verticalRight, levels).forEach { (lab, val) in
            lab.valueFormatter = formatter
            lab.attachedValue = val
        }
    }
    
    private func generateValueLevels(maxVal: Float, levelsCount count: Int) -> [Float] {
        return (0..<count).map({maxVal * Float($0) / Float(count)})
    }
}
