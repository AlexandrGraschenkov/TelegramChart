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
    
    var topDateLabel: UILabel!
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
                if chartType == .percentage {
                    selectInfo.onTapClosure = { [weak self] in
                        self?.openDetail()
                    }
                }
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
            updateTopLabelDates()
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
    
    func setDisplayDataOnly(index: Int, animated: Bool) {
        guard let groupData = data else { return }
        if index < 0 || index >= groupData.data.count { return }
        
        let count = groupData.data.count
        for i in 0..<count {
            groupData.data[i].visible = i == index
        }
        if visibleData.count > 0 {
            runMaxValueChangeAnimation(data: visibleData, animDuration: maxValDuration)
        }
        runShowHideAnimation(visible: (0..<count).map{$0 == index}, animDuration: alphaDuration)
        if selectInfo.isDisplayed {
            selectInfo.updateInfoSelectedDate(date: selectInfo.lastSelectionDate, data: visibleData, forceUpdateContent: true)
        }
    }
    
    func update(apereance: Apereance) {
        backgroundColor = apereance.bg
        topDateLabel.textColor = apereance.textColor
        let clear = apereance.bg.myColor.metalClear
        displayChart.metal.clearColor = clear
        selectionChart.metal.clearColor = clear
        displayChart.gridColor = apereance.gridColor.myColor
        selectionView.update(apereance: apereance)
        selectInfo.update(apereance: apereance)
        displayChart.labelsPool.color = apereance.chartTextColor
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
    
    private lazy var dateFormatter: (Int64)->(String) = {
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        return { (time: Int64) -> String in
            return df.string(from: Date(timeIntervalSince1970: TimeInterval(time) / 1000.0))
        }
    }()
    private var visibleData: [ChartData] {
        guard let groupData = data else {
            return []
        }
        return groupData.data.filter({$0.visible})
    }
    private var cancelShowHideAnimation: [Int: Cancelable] = [:]
    private var panGesture: UIPanGestureRecognizer!
    
    private func setup() {
        displayChart = ChartView()
        displayChart.backgroundColor = backgroundColor
        displayChart.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - selectionHeight)
        addSubview(displayChart)
        
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
        
        topDateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 30))
        topDateLabel.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        topDateLabel.font = UIFont.boldSystemFont(ofSize: 13)
        topDateLabel.textColor = Apereance.day.textColor
        topDateLabel.textAlignment = .center
        addSubview(topDateLabel)
        
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
    
    private func updateTopLabelDates() {
        let from = displayChart.displayRange.from
        let to = displayChart.displayRange.to
        if to <= 0 {
            topDateLabel.text = ""
            return
        }
        topDateLabel.text = dateFormatter(from) + " - " + dateFormatter(to)
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
    
    private func runShowHideAnimation(visible: [Bool], animDuration: Double) {
        let animIdx = displayChart.dataAlpha.count
        cancelShowHideAnimation[animIdx]?()
        let startAlpha = displayChart.dataAlpha
        let endAlpha = visible.map{$0 ? CGFloat(1) : CGFloat(0)}
        let cancel = DisplayLinkAnimator.animate(duration: animDuration) { (progress) in
            let progress = -progress * (progress - 2) // ease out
            for i in 0..<startAlpha.count {
                let alpha = (endAlpha[i] - startAlpha[i]) * progress + startAlpha[i]
                self.displayChart.dataAlpha[i] = alpha
                self.selectionChart.dataAlpha[i] = alpha
            }
            if !self.displayChart.isMaxValAnimating {
                self.displayChart.metal.setNeedsDisplay()
            }
            if !self.selectionChart.isMaxValAnimating {
                self.selectionChart.metal.setNeedsDisplay()
            }
            if progress == 1 {
                self.cancelShowHideAnimation[animIdx] = nil
            }
        }
        cancelShowHideAnimation[animIdx] = cancel
    }
    
    @objc func userSelectDate(gesture: UIGestureRecognizer) {
        let ppp = gesture.location(in: selectInfo.infoView)
        if selectInfo.infoView.bounds.contains(ppp) {
            openDetail()
            return
        }
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
        
        updateTopLabelDates()
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
    
    
    func openDetail() {
        lastDisplay = lastDisplay ?? displayChart.metal.display as! PercentFillDisplay
        if displayChart.metal.display is PercentPieTransitionDisplay {
            displayChart.metal.display = lastDisplay
        } else {
            let pie = PercentPieTransitionDisplay(percentFill: lastDisplay!, day: selectInfo.lastSelectionDate)
            displayChart.metal.display = pie
        }
        displayChart.metal.setNeedsDisplay()
    }
}
private var lastDisplay: PercentFillDisplay?

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
