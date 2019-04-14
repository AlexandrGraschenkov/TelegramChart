//
//  ChartCell.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 12/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit


class ChartCell: UITableViewCell {

    @IBOutlet weak var chart: ChartCopmosedView!
    @IBOutlet weak var selectChart: SelectChartDisplayedView!
    var groupData: ChartGroupData?
    
    
    
    static func getHeight(withData data: ChartGroupData, width: CGFloat) -> CGFloat {
        let chartHeigth: CGFloat = 300
        let selectHeight: CGFloat = SelectChartDisplayedView.getHeightAndLayout(groupData: data, fixedWidth: width)
        return chartHeigth + selectHeight
    }
    
    func display(groupData: ChartGroupData) {
        self.groupData = groupData
        chart.data = groupData
        selectChart.display(groupData: groupData)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        chart.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 300)
        selectChart.frame = bounds.inset(by: UIEdgeInsets(top: 300, left: 0, bottom: 0, right: 0))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectChart.displayDelegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension ChartCell: SelectChartDisplayedViewDelegate {
    func chartDataRequestDisplayChange(index: Int, display: Bool) -> Bool {
        guard let groupData = groupData else {
            return false
        }
        var displayCount = 0
        for (idx, d) in groupData.data.enumerated() {
            let isVisible = (idx == index) ? display : d.visible
            if isVisible {
                displayCount += 1
            }
        }
        if displayCount == 0 {
            return false
        }
        
        groupData.data[index].visible = display
        chart.setDisplayData(index: index, display: display, animated: true)
        return true
    }
}
