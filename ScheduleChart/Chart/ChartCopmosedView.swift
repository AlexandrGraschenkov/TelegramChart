//
//  ChartCopmosedView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 20/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ChartCopmosedView: UIView {

    enum Mode {
        case night
        case day
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    var levelsCount: Int = 5
    var selectionChart: ChartView!
    var displayChart: ChartView!
    var selectionView: ChartSelectionView!
    var selectionHeight: CGFloat = 40 {
        didSet { setNeedsLayout(); layoutIfNeeded() }
    }
    
    var mode: Mode = .day {
        didSet { updateMode() }
    }
    
    var data: ChartGroupData? {
        didSet {
            cancelShowHideAnimation.values.forEach({$0()})
            cancelShowHideAnimation.removeAll()
            selectionChart.data = data
            displayChart.data = data
            
            guard let groupData = data else {
                return
            }
            
            let maxVal: Float
            if groupData.type == .percentage {
                maxVal = 125
            } else {
                let stacked = groupData.type == .stacked
                maxVal = DataMaxValCalculator.getMaxValue(visibleData, stacked: stacked, dividableBy: levelsCount)
            }
            selectionChart.setMaxVal(val: maxVal, animationDuration: 0)
            displayChart.setMaxVal(val: maxVal, animationDuration: 0)
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
        if let date = displayChart.selectedDate, selectInfoView != nil {
            updateInfoSlectedDate(date: date)
        }
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
    private var selectInfoBgColor: UIColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00) {
        didSet {
            selectInfoView?.bgColor = selectInfoBgColor
        }
    }
    private var maxValDuration: Double = 0.3
    private var alphaDuration: Double = 0.3
    private var selectInfoView: SelctionInfoView?
    private var visibleData: [ChartData] {
        guard let groupData = data else {
            return []
        }
        return groupData.data.filter({$0.visible})
    }
    private var cancelShowHideAnimation: [Int: Cancelable] = [:]
    private var panGesture: UIPanGestureRecognizer!
    
    static var test = 0
    private func setup() {
        ChartCopmosedView.test += 1
        print("••••Chart count", ChartCopmosedView.test)
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
        selectInfoView?.removeFromSuperview()
        selectInfoView = nil
    }
        
    private func updateMode() {
        selectionView.mode = mode
        switch mode {
        case .day:
            let bg = Color(w: 1, a: 1)
            backgroundColor = bg.uiColor
            displayChart.metal.clearColor = bg.metalClear
            selectionChart.metal.clearColor = bg.metalClear
            
            displayChart.gridColor = Color(w: 0.45, a: 0.2)
            selectInfoBgColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00)
        case .night:
            let bg = Color(r: 0.14, g: 0.18, b: 0.24, a: 1)
            backgroundColor = bg.uiColor
            displayChart.metal.clearColor = bg.metalClear
            selectionChart.metal.clearColor = bg.metalClear
            
            displayChart.gridColor = Color(r: 0.22, g: 0.3, b: 0.4, a: 0.5)
            selectInfoBgColor = UIColor(red:0.11, green:0.16, blue:0.21, alpha:1.00)
        }
        displayChart.updateLevels()
        displayChart.metal.setNeedsDisplay()
        selectionChart.metal.setNeedsDisplay()
    }
    
    // MARK: show\hide animation
    private func runMaxValueChangeAnimation(data: [ChartData], animDuration: Double) {
        if displayChart.metal.display.groupMode == .percentage {
            return
        }
        let stacked = self.data?.type == .stacked
        let totalMaxVal = DataMaxValCalculator.getMaxValue(data, stacked: stacked, dividableBy: levelsCount)
        selectionChart.setMaxVal(val: totalMaxVal, animationDuration: animDuration)
        
        
        let fromTime = displayChart.displayRange.from
        let toTime = displayChart.displayRange.to
        let displayMaxVal = DataMaxValCalculator.getMaxValue(data, fromTime: fromTime, toTime: toTime, stacked: stacked, dividableBy: levelsCount)
        displayChart.setMaxVal(val: displayMaxVal, animationDuration: animDuration)
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
        displayChart.selectedDate = closestDate
        if let date = closestDate {
            updateInfoSlectedDate(date: date)
        }
    }
    
    private func updateInfoSlectedDate(date: Int64) {
        if selectInfoView == nil {
            selectInfoView = SelctionInfoView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            selectInfoView?.bgColor = selectInfoBgColor
            addSubview(selectInfoView!)
        }
        if let view = selectInfoView {
            view.update(data: visibleData, time: date)
            let centerX = displayChart.getXPos(date: date)
            let frame = CGRect(x: round(centerX - view.bounds.width / 2.0),
                               y: 5,
                               width: view.bounds.width,
                               height: view.bounds.height)
            view.frame = convert(frame, from: displayChart)
            //            selectInfoView?.center =
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
        
        if displayChart.metal.display.groupMode == .percentage {
            return
        }
        
        let stacked = data?.type == .stacked
        let maxVal = DataMaxValCalculator.getMaxValue(visibleData, fromTime: fromTime, toTime: toTime, stacked: stacked, dividableBy: levelsCount)
        if maxVal != 0 {
            displayChart.setMaxVal(val: maxVal, animationDuration: maxValDuration)
        }
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
