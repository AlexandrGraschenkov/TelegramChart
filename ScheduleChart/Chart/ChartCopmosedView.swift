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
    
    var data: [ChartData] = [] {
        didSet {
            cancelShowHideAnimation.values.forEach({$0()})
            cancelShowHideAnimation.removeAll()
            selectionChart.data = data
            displayChart.data = data
            
            dataIsVisible = Array(repeating: true, count: data.count)
            let maxVal = DataMaxValCalculator.getMaxValue(data, dividableBy: levelsCount)
            selectionChart.setMaxVal(val: maxVal, animationDuration: 0)
            displayChart.setMaxVal(val: maxVal, animationDuration: 0)
            selectionView.range = ChartSelectionView.Range(from: 0, to: 1)
        }
    }
    
    func setShowData(index: Int, show: Bool, animated: Bool) {
        if index < 0 || index >= dataIsVisible.count { return }
        if dataIsVisible[index] == show { return }
        
        dataIsVisible[index] = show
        let animDuration: Double = 0.2
        
        if visibleData.count > 0 {
            runMaxValueChangeAnimation(data: visibleData, animDuration: animDuration)
        }
        runShowHideAnimation(dataIndex: index, show: show, animDuration: animDuration)
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
    
    
    // mark: private
    private var dataIsVisible: [Bool] = []
    private var visibleData: [ChartData] {
        return zip(data, dataIsVisible).compactMap({$0.1 ? $0.0 : nil})
    }
    private var cancelShowHideAnimation: [Int: Cancelable] = [:]
    
    private func setup() {
        selectionChart = ChartView()
        selectionChart.lineWidth = 1.5
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
        
        displayChart = ChartView()
        displayChart.backgroundColor = backgroundColor
        displayChart.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - selectionHeight)
        addSubview(displayChart)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(userSelectDate(gesture:)))
        displayChart.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userSelectDate(gesture:)))
        displayChart.addGestureRecognizer(tap)
    }
        
    private func updateMode() {
        selectionView.mode = mode
        switch mode {
        case .day:
            backgroundColor = .white
            displayChart.gridColor = UIColor(white: 0.9, alpha: 1.0)
        case .night:
            backgroundColor = UIColor(red:0.14, green:0.18, blue:0.24, alpha:1.00)
            displayChart.gridColor = UIColor(red:0.11, green:0.15, blue:0.20, alpha:1.00)
        }
    }
    
    // mark: show\hide animation
    private func runMaxValueChangeAnimation(data: [ChartData], animDuration: Double) {
        let totalMaxVal = DataMaxValCalculator.getMaxValue(data, dividableBy: levelsCount)
        selectionChart.setMaxVal(val: totalMaxVal, animationDuration: animDuration)
        
        
        let fromTime = displayChart.displayRange.from
        let toTime = displayChart.displayRange.to
        let displayMaxVal = DataMaxValCalculator.getMaxValue(data, fromTime: fromTime, toTime: toTime, dividableBy: levelsCount)
        displayChart.setMaxVal(val: displayMaxVal, animationDuration: animDuration)
    }
    
    private func runShowHideAnimation(dataIndex index: Int, show: Bool, animDuration: Double) {
        cancelShowHideAnimation[index]?()
        let startAlpha = displayChart.dataAlpha[index]
        let endAlpha: CGFloat = show ? 1 : 0
        let cancel = DisplayLinkAnimator.animate(duration: animDuration) { (progress) in
            let alpha = (endAlpha - startAlpha) * progress + startAlpha
            self.displayChart.dataAlpha[index] = alpha
            self.selectionChart.dataAlpha[index] = alpha
            if !self.displayChart.isMaxValAnimating {
                self.displayChart.setNeedsDisplay()
            }
            if !self.selectionChart.isMaxValAnimating {
                self.selectionChart.setNeedsDisplay()
            }
            if progress == 1 {
                self.cancelShowHideAnimation[index] = nil
            }
        }
        cancelShowHideAnimation[index] = cancel
    }
    
    @objc func userSelectDate(gesture: UIGestureRecognizer) {
        if gesture.state == .cancelled { return }
        if data.count == 0 { return }
        let pos = gesture.location(in: displayChart)
        guard let date = displayChart.getDate(forPos: pos) else {
            displayChart.selectedDate = nil
            return
        }
        
        // can be boosted
        var closestDate: Int64?
        for item in data[0].items {
            guard let cDate = closestDate else {
                closestDate = item.time
                continue
            }
            
            if abs(cDate - date) > abs(date - item.time) {
                closestDate = item.time
            }
        }
        displayChart.selectedDate = closestDate
    }
}

extension ChartCopmosedView: ChartSelectionViewDelegate {
    func selectionRangeChanged(_ selctionView: ChartSelectionView, range: ChartSelectionView.Range) {
        let minTime = displayChart.dataMinTime
        let maxTime = displayChart.dataMaxTime
        let fromTime = Int64(CGFloat(maxTime - minTime) * range.from) + minTime
        let toTime = Int64(CGFloat(maxTime - minTime) * range.to) + minTime
        displayChart.setRange(minTime: fromTime, maxTime: toTime, animated: false)
        let maxVal = DataMaxValCalculator.getMaxValue(visibleData, fromTime: fromTime, toTime: toTime, dividableBy: levelsCount)
        displayChart.setMaxVal(val: maxVal, animationDuration: 0.2)
    }
}
