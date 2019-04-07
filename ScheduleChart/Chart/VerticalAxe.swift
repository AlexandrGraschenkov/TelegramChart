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
    
    
    func redraw(inset: UIEdgeInsets) {
        let drawMaxVal = view.maxValue
        
        var attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        attachedLabels.sort(by: {$0.alpha < $1.alpha})
        let frame = view.bounds.inset(by: UIEdgeInsets(top: inset.top, left: 0, bottom: inset.bottom, right: 0))
        for lab in attachedLabels {
            guard let val = lab.attachedValue else { continue }
            if lab.alpha == 0 { continue }
            
            var y = frame.height * CGFloat(1 - val / drawMaxVal) + frame.origin.y
            y = round(y)
            
            lab.frame.origin = CGPoint(x: frame.minX + inset.left - lab.frame.width,
                                       y: y - lab.frame.height)
            lab.shapeLayer?.position = CGPoint(x: 0, y: y)
        }
    }
    
    private func resizeVerticalIfNeeded() -> Bool {
        var changed = false
        while vertical.count < levelsCount {
            let lab = labelsPool.getUnused()
            if lab.shapeLayer == nil {
                let shape = generateLineShape()
                shape.position = CGPoint(x: 0, y: lab.frame.maxY)
                lab.shapeLayer = shape
            }
            view.addSubview(lab)
            view.layer.insertSublayer(lab.shapeLayer!, at: 0)
            vertical.append(lab)
            changed = true
        }
        while vertical.count > levelsCount {
            let label = vertical.removeLast()
            label.removeFromSuperview()
            label.shapeLayer?.removeFromSuperlayer()
            changed = true
        }
        return changed
    }
    
    private func generateLineShape() -> ShapeLayer {
        let shape = ShapeLayer()
        shape.fillColor = nil
        shape.lineWidth = 0.5
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: shape.lineWidth / 2))
        // I don't wanna handle device orientation change
        let maxDeviceSide = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        path.addLine(to: CGPoint(x: maxDeviceSide, y: shape.lineWidth / 2))
        shape.path = path
        
        shape.strokeColor = gridColor.cgColor
        return shape
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
