//
//  HorisontalAxe.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 14/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class HorisontalAxe: NSObject {
    var show: Bool = true
    let view: ChartView
    let labelsPool: LabelsPool = LabelsPool()
    
    var timeFormater: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM"
        return df
    }()
    
    var horisontal: [AttachedLabel] = []
    var minHorisontalSpacing: CGFloat = 70.0
    var maxHorisontalSpacing: CGFloat = 120.0
    var firstDate: Int64 { return view.dataMinTime }
    var lastDate: Int64 { return view.dataMaxTime }
    let dayOffset: Int64 = 86400000
    private(set) var minTime: Int64 = 0
    private(set) var maxTime: Int64 = 0
    
    init(view: ChartView) {
        self.view = view
        super.init()
    }
    
    private var skipPowCount = 0
    private var skipCount: CGFloat {
        return pow(2, CGFloat(skipPowCount))
    }
    
    func setRange(minTime: Int64, maxTime: Int64, animationDuration duration: Double = 0) {
        // we need display bottom labels on all visible range
        // include chart inset in display range
        if self.minTime == minTime && self.maxTime == maxTime {
            return
        }
        self.minTime = minTime
        self.maxTime = maxTime
        
        let expandLeftPercent = ((view.bounds.width + view.chartInset.left) / view.bounds.width)
        let displayMinTime = Int64(CGFloat(minTime - maxTime) * expandLeftPercent) + maxTime
        let expandRightPercent = ((view.bounds.width + view.chartInset.right) / view.bounds.width)
        let displayMaxTime = Int64(CGFloat(maxTime - minTime) * expandRightPercent) + minTime
        
        let width = view.bounds.width
        let times = getDisplayTimes(minTime: displayMinTime, maxTime: displayMaxTime, width: width)
        let animated = duration>0
        let (addLabels, dismissLabels) = updateHorisontal(times: times, reuse: !animated)
        if addLabels.count == 0 && dismissLabels.count == 0 {
            return
        }
        if animated {
            _ = AttachedLabelAnimator.animateAppearDismiss(appear: addLabels, dismiss: dismissLabels, duration: duration)
        } else {
            dismissLabels.forEach({$0.unuse()})
            addLabels.forEach({$0.alpha = 1})
        }
        layoutLabels()
    }
    
    private func getDisplayTimes(minTime: Int64, maxTime: Int64, width: CGFloat) -> [Int64] {
        let daysCount: Double = Double(maxTime - minTime) / Double(dayOffset)
        let getSpacing = { ()->CGFloat in
            let displayCount = CGFloat(daysCount + 1) / self.skipCount
            return width / displayCount
        }
        
        while getSpacing() < minHorisontalSpacing {
            skipPowCount += 1
        }
        
        while skipPowCount > 0 && getSpacing() > maxHorisontalSpacing {
            skipPowCount -= 1
        }
        
        let maxDaysCount = (lastDate - firstDate) / dayOffset
        
        var start = (minTime - firstDate) / dayOffset
        start = max(0, start - Int64(skipCount))
        let to = (maxTime - firstDate) / dayOffset + Int64(skipCount)
        var displayValues: [Int64] = []
        for i in start...to {
            if Int(i) % Int(skipCount) != 0 { continue }
            if maxDaysCount - i < Int64(skipCount) {
                // we want to display last day not depend on spacing
                displayValues.append(lastDate)
                break
            }
            displayValues.append(i*dayOffset + firstDate)
        }
        return displayValues
    }
    
    private func updateHorisontal(times: [Int64], reuse: Bool) -> (added: [AttachedLabel], dismissed: [AttachedLabel]) {
        var keep: [AttachedLabel] = []
        var added: [AttachedLabel] = []
        var dismissed: [AttachedLabel] = []
        for l in horisontal {
            guard let time = l.attachedTime else {
                l.removeFromSuperview()
                continue
            }
            if times.contains(time) {
                keep.append(l)
            } else {
                dismissed.append(l)
            }
        }
        
        for (idx, time) in times.enumerated() {
            if idx < keep.count && keep[idx].attachedTime == time {
                continue
            }
            var lab: AttachedLabel! = reuse ? dismissed.popLast() : nil
            lab = lab ?? labelsPool.getUnused()
            if lab.attachedTime == nil {
                added.append(lab)
                let tf = timeFormater
                lab.timeFormatter = {tf.string(from: Date(timeIntervalSince1970: Double($0)))}
            }
            lab.attachedTime = time
            if lab.superview != view {
                view.addSubview(lab)
            }
            keep.insert(lab, at: idx)
        }
        horisontal = keep
        return (added, dismissed)
    }
    
    func layoutLabels() {
        let attachedLabels: [AttachedLabel] = view.subviews.compactMap({$0 as? AttachedLabel})
        let chartFrame = view.bounds.inset(by: view.chartInset)
        let labSize = CGSize(width: minHorisontalSpacing, height: view.chartInset.bottom)
        let labY: CGFloat = view.bounds.height - view.chartInset.bottom / 2.0
        
        let minTime = view.displayRange.from
        let maxTime = view.displayRange.to
        for lab in attachedLabels {
            guard let time = lab.attachedTime else { continue }
            if lab.bounds.size != labSize {
                lab.frame.size = labSize
            }
            let percent = CGFloat(time - minTime) / CGFloat(maxTime - minTime)
            let labX: CGFloat = percent * chartFrame.width + chartFrame.origin.x
            lab.center = CGPoint(x: labX, y: labY)
        }
    }
}
