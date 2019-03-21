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
    
    var selectionChart: ChartView!
    var displayChart: ChartView!
    var selectionView: ChartSelectionView!
    var selectionHeight: CGFloat = 40 {
        didSet { setNeedsLayout(); layoutIfNeeded() }
    }
    
    var data: [ChartData] = [] {
        didSet {
            selectionChart.data = data
            displayChart.data = data
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
