//
//  SelectChartDisplayedView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 23/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

struct ChartDataInfo {
    let name: String
    let color: UIColor
    var selected: Bool
    
    static func mapInfoFrom(data: [ChartData]) -> [ChartDataInfo] {
        return data.enumerated().map({ (offset, element) -> ChartDataInfo in
            return ChartDataInfo(name: element.name ?? "Data \(offset)",
                color: element.color,
                selected: true)
        })
    }
}

protocol SelectChartDisplayedViewDelegate: class {
    func chartDataDisplayChanged(index: Int, display: Bool)
}

class SelectChartDisplayedView: UIScrollView {
    
    weak var displayDelegate: SelectChartDisplayedViewDelegate?
    
    var items: [ChartDataInfo] = [] {
        didSet {
            updateButtons()
        }
    }
    
    var titleColor: UIColor = .black {
        didSet {
            buttons.forEach({$0.setTitleColor(titleColor, for: .normal)})
        }
    }
    
    
    // mark: private
    private lazy var selectedIcon = UIImage(named: "selected_icon")?.withRenderingMode(.alwaysTemplate)
    private lazy var deselectedIcon = UIImage(named: "unselected_icon")?.withRenderingMode(.alwaysTemplate)
    private lazy var bgImage = UIImage(named: "borders")?.resizableImage(withCapInsets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
    private var buttons: [UIButton] = []
    private var buttHeight: CGFloat = 40.0
    
    private func updateButtons() {
        while buttons.count > items.count {
            buttons.popLast()?.removeFromSuperview()
        }
        while buttons.count < items.count {
            buttons.append(generateButton())
        }
        
        var offset: CGPoint = CGPoint(x: 10, y: (bounds.height - buttHeight) / 2.0)
        for (item, butt) in zip(items, buttons) {
            butt.setTitle(item.name, for: .normal)
            butt.tintColor = item.color
            butt.isSelected = item.selected
            let fitSize = butt.sizeThatFits(CGSize(width: 200, height: buttHeight))
            let fitWidth = ceil(fitSize.width) + 10.0
            butt.frame = CGRect(x: offset.x, y: offset.y, width: fitWidth, height: buttHeight)
            offset.x = butt.frame.maxX + 10
        }
        contentSize = CGSize(width: offset.x, height: 0)
    }
    
    private func generateButton() -> UIButton {
        let butt = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: buttHeight))
        butt.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        butt.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        butt.setTitleColor(titleColor, for: .normal)
        butt.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 10)
        butt.titleEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
        butt.setBackgroundImage(bgImage, for: .normal)
        butt.setImage(selectedIcon, for: .selected)
        butt.setImage(deselectedIcon, for: .normal)
        butt.addTarget(self, action: #selector(itemButtonPressed(_:)), for: .touchUpInside)
        addSubview(butt)
        return butt
    }
    
    @objc func itemButtonPressed(_ butt: UIButton) {
        guard let idx = buttons.firstIndex(of: butt) else {
            return
        }
        
        butt.isSelected = !butt.isSelected
        displayDelegate?.chartDataDisplayChanged(index: idx, display: butt.isSelected)
    }
}
