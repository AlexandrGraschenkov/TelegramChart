//
//  ChartCopmosedView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 20/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ChartCopmosedView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    var levelsCount: Int = 5
    var minValueFixedZero: Bool = true
    var selectionChart: ChartView!
    var displayChart: ChartView!
    var selectionView: ChartSelectionView!
    var selectionHeight: CGFloat = 40 {
        didSet { setNeedsLayout(); layoutIfNeeded() }
    }
    
    var data: ChartGroupData? {
        didSet {
            if oldValue == data { return }
            if let chartType = data?.type {
                selectInfo.selectionDisplay.setChartType(chartType)
            } else {
                selectInfo.selectionDisplay.deselect()
            }
            
            cancelShowHideAnimation.values.forEach({$0()})
            cancelShowHideAnimation.removeAll()
            selectionChart.data = data
            displayChart.data = data
            
            guard let groupData = data else {
                return
            }
            
            if groupData.scaled {
                displayChart.chartInset.right = 40
                let maxValues = groupData.data.map({DataMaxValCalculator.getMinMaxValue([$0], stacked: false, dividableBy: levelsCount).1})
                let maxValue: Float = maxValues.reduce(Float(0), max)
                customScale = maxValues.map({maxValue / $0})
                displayChart.verticalAxe.setupRightLabels(rightScale: customScale[1], leftColor: groupData.data[0].color, rightColor: groupData.data[1].color)
            } else {
                displayChart.chartInset.right = 30
                customScale = []
                displayChart.verticalAxe.resetRightLabels()
            }
            displayChart.metal.customScale = customScale
            selectionChart.metal.customScale = customScale
            
            let maxVal: Float
            let minVal: Float
            if groupData.type == .percentage {
                maxVal = 125
                minVal = 0
            } else {
                (minVal, maxVal) = getMinMaxValue()
            }
            selectionChart.setMaxVal(val: maxVal, minVal: minVal, animationDuration: 0)
            displayChart.setMaxVal(val: maxVal, minVal: minVal, animationDuration: 0)
            resetState()
        }
    }
    
    func setDisplayData(index: Int, display: Bool, animated: Bool) {
        guard let groupData = data else { return }
        if index < 0 || index >= groupData.data.count { return }
        
        if groupData.data[index].visible != display {
            groupData.data[index].visible = display
        }
        if visibleData.count > 0 {
            runMaxValueChangeAnimation(data: visibleData, animDuration: maxValDuration)
        }
        runShowHideAnimation(dataIndex: index, show: display, animDuration: alphaDuration)
        if selectInfo.isDisplayed {
            selectInfo.updateInfoSelectedDate(date: selectInfo.lastSelectionDate, data: visibleData, forceUpdateContent: true)
        }
    }
    
    func update(apereance: Apereance) {
        backgroundColor = apereance.bg
        let clear = apereance.bg.myColor.metalClear
        displayChart.metal.clearColor = clear
        selectionChart.metal.clearColor = clear
        displayChart.gridColor = apereance.gridColor.myColor
        selectionView.update(apereance: apereance)
        selectInfo.update(apereance: apereance)
        displayChart.labelsPool.color = apereance.chartTextColor
        
        //        switch mode {
        //        case .day:
        //            let bg = Color(w: 1, a: 1)
        //            backgroundColor = bg.uiColor
        //            displayChart.metal.clearColor = bg.metalClear
        //            selectionChart.metal.clearColor = bg.metalClear
        //
        //            displayChart.gridColor = Color(w: 0.45, a: 0.2)
        //            selectInfo.bgColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00)
        //        case .night:
        //            let bg = Color(r: 0.14, g: 0.18, b: 0.24, a: 1)
        //            backgroundColor = bg.uiColor
        //            displayChart.metal.clearColor = bg.metalClear
        //            selectionChart.metal.clearColor = bg.metalClear
        //
        //            displayChart.gridColor = Color(r: 0.22, g: 0.3, b: 0.4, a: 0.5)
        //            selectInfo.bgColor = UIColor(red:0.11, green:0.16, blue:0.21, alpha:1.00)
        //        }
        displayChart.updateLevels()
        displayChart.metal.setNeedsDisplay()
        selectionChart.metal.setNeedsDisplay()
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            displayChart?.backgroundColor = backgroundColor
            selectionChart?.backgroundColor = backgroundColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var chartFrame = bounds
        chartFrame.size.height -= selectionHeight
        displayChart.frame = chartFrame
        
        chartFrame.origin.y = bounds.height - selectionHeight
        chartFrame.size.height = selectionHeight
        selectionChart.frame = chartFrame.insetBy(dx: 15, dy: 0)
    }
    
    
    // MARK: private
    private lazy var selectInfo: SelectionInfoBehavior = SelectionInfoBehavior(chart: self.displayChart)
    private var customScale: [Float] = []
    private var maxValDuration: Double = 0.3
    private var alphaDuration: Double = 0.3
    private var visibleData: [ChartData] {
        guard let groupData = data else {
            return []
        }
        return groupData.data.filter({$0.visible})
    }
    private var cancelShowHideAnimation: [Int: Cancelable] = [:]
    private var panGesture: UIPanGestureRecognizer!
    
    private func setup() {
        selectionChart = ChartView()
        selectionChart.isSelectionView = true
        selectionChart.backgroundColor = backgroundColor
        selectionChart.drawGrid = false
        selectionChart.chartInset = UIEdgeInsets.zero
        selectionChart.frame = CGRect(x: 0, y: 0, width: bounds.width, height: selectionHeight)
        selectionChart.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        addSubview(selectionChart)
        
        selectionView = ChartSelectionView(frame: selectionChart.bounds)
        selectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        selectionView.delegate = self
        selectionChart.addSubview(selectionView)
        selectionView.setupGestures(view: self)
        
        displayChart = ChartView()
        displayChart.backgroundColor = backgroundColor
        displayChart.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - selectionHeight)
        addSubview(displayChart)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(userSelectDate(gesture:)))
        pan.delegate = self
        displayChart.addGestureRecognizer(pan)
        panGesture = pan
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userSelectDate(gesture:)))
        displayChart.addGestureRecognizer(tap)
    }
    
    private func resetState() {
        selectionView.range = ChartSelectionView.Range(from: 0, to: 1)
        displayChart.selectedDate = nil
        selectInfo.dismissSelectedDate(animated: false)
    }
    
    // MARK: show\hide animation
    private func runMaxValueChangeAnimation(data: [ChartData], animDuration: Double) {
        if displayChart.metal.display.groupMode == .percentage {
            return
        }
        let (totalMinVal, totalMaxVal) = getMinMaxValue()
        selectionChart.setMaxVal(val: totalMaxVal, minVal: totalMinVal, animationDuration: animDuration)
        
        
        let fromTime = displayChart.displayRange.from
        let toTime = displayChart.displayRange.to
        let displayMinMax = getMinMaxValue(fromTime: fromTime, toTime: toTime)
        displayChart.setMaxVal(val: displayMinMax.1, minVal: displayMinMax.0, animationDuration: animDuration)
    }
    
    private func runShowHideAnimation(dataIndex index: Int, show: Bool, animDuration: Double) {
        cancelShowHideAnimation[index]?()
        let startAlpha = displayChart.dataAlpha[index]
        let endAlpha: CGFloat = show ? 1 : 0
        let cancel = DisplayLinkAnimator.animate(duration: animDuration) { (progress) in
            let progress = -progress * (progress - 2) // ease out
            let alpha = (endAlpha - startAlpha) * progress + startAlpha
            self.displayChart.dataAlpha[index] = alpha
            self.selectionChart.dataAlpha[index] = alpha
            if !self.displayChart.isMaxValAnimating {
                self.displayChart.metal.setNeedsDisplay()
            }
            if !self.selectionChart.isMaxValAnimating {
                self.selectionChart.metal.setNeedsDisplay()
            }
            if progress == 1 {
                self.cancelShowHideAnimation[index] = nil
//                self.setShowData(index: index, show: !show, animated: true)
            }
        }
        cancelShowHideAnimation[index] = cancel
    }
    
    @objc func userSelectDate(gesture: UIGestureRecognizer) {
        if gesture.state == .cancelled { return }
        guard let groupData = data, groupData.data.count > 0 else { return }
        
        let pos = gesture.location(in: displayChart)
        guard let date = displayChart.getDate(forPos: pos) else {
            displayChart.selectedDate = nil
            return
        }
        
        let closestDate: Int64? = groupData.getClosestDate(date: date)?.1
        if let date = closestDate {
            selectInfo.updateInfoSelectedDate(date: date, data: visibleData, forceUpdateContent: false)
        }
    }
    
}

extension ChartCopmosedView: ChartSelectionViewDelegate {
    func selectionRangeChanged(_ selctionView: ChartSelectionView, range: ChartSelectionView.Range) {
        let minTime = displayChart.dataMinTime
        let maxTime = displayChart.dataMaxTime
        let fromTime = Int64(CGFloat(maxTime - minTime) * range.from) + minTime
        let toTime = Int64(CGFloat(maxTime - minTime) * range.to) + minTime
        displayChart.setRange(minTime: fromTime, maxTime: toTime, animated: false)
        if visibleData.count == 0 { return }
        
        if displayChart.metal.display.groupMode != .percentage {
            let (minVal, maxVal) = getMinMaxValue(fromTime: fromTime, toTime: toTime)
            if maxVal != 0 {
                displayChart.setMaxVal(val: maxVal, minVal: minVal, animationDuration: maxValDuration)
            }
        }
        
        selectInfo.updateInfoFrame(dataUpdated: nil)
    }
    
    func getMinMaxValue(fromTime: Int64? = nil, toTime: Int64? = nil) -> (Float, Float) {
        guard let groupData = data else { return (0,0) }
        
        if customScale.count == 0 {
            let stacked = data?.type == .stacked
            return DataMaxValCalculator.getMinMaxValue(visibleData, fromTime: fromTime, toTime: toTime, stacked: stacked, withMinValue: !minValueFixedZero, dividableBy: levelsCount)
        }
        
        var maxVal: Float = 0
        var minVal: Float!
        for (scale, d) in zip(customScale, groupData.data) {
            if !d.visible { continue }
            var (val0, val1) = DataMaxValCalculator.getMinMaxValue([d], fromTime: fromTime, toTime: toTime, stacked: false, withMinValue: !minValueFixedZero, dividableBy: levelsCount)
            val1 *= scale
            val0 *= scale
            if val1 > maxVal {
                maxVal = val1
            }
            if minVal == nil || val0 < minVal {
                minVal = val0
            }
        }
        return (minVal, maxVal)
    }
}

extension ChartCopmosedView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            let t = panGesture!.translation(in: self)
            if abs(t.y) < abs(t.x) {
                otherGestureRecognizer.isEnabled = false
                otherGestureRecognizer.isEnabled = true
            }
        }
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        if self.panGesture != g {
            return super.gestureRecognizerShouldBegin(g)
        }
        
        if let pan = g as? UIPanGestureRecognizer {
            let t = pan.translation(in: self)
            if abs(t.y) > abs(t.x) {
                return false
            }
        }
        return true
    }
}
