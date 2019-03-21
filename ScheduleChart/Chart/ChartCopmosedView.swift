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
            selectionChart.data = data
            displayChart.data = data
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
    }
        
    func updateMode() {
        switch mode {
        case .day:
            backgroundColor = .white
            displayChart.verticalAxe.gridColor = UIColor(white: 0.9, alpha: 1.0)
        case .night:
            backgroundColor = UIColor(red:0.14, green:0.18, blue:0.24, alpha:1.00)
            displayChart.verticalAxe.gridColor = UIColor(red:0.11, green:0.15, blue:0.20, alpha:1.00)
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
    }
}
