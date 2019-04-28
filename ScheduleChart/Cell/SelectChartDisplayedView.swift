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
    
    static func mapInfoFrom(groupData: ChartGroupData) -> [ChartDataInfo] {
        return groupData.data.enumerated().map({ (offset, element) -> ChartDataInfo in
            return ChartDataInfo(name: element.name ?? "Data \(offset)",
                color: element.color,
                selected: element.visible)
        })
    }
}

protocol SelectChartDisplayedViewDelegate: class {
    func chartDataRequestDisplayChange(index: Int, display: Bool) -> Bool
    func displayOnly(index: Int)
}

class SelectChartDisplayedView: UIView {
    
    private static let defaultFont: UIFont = UIFont.systemFont(ofSize: 15)
    
    static func getHeightAndLayout(groupData: ChartGroupData, fixedWidth: CGFloat, layoutButtons: [UIButton] = []) -> CGFloat {
        let infos = ChartDataInfo.mapInfoFrom(groupData: groupData)
        if infos.count <= 1 {
            return 0
        }
        
        let buttAdditionalWidth: CGFloat = 40
        let heightStep: CGFloat = 10
        let xStep: CGFloat = 10
        let buttHeight: CGFloat = 30
        var offset: CGPoint = CGPoint(x: xStep, y: heightStep)
        for (idx, info) in infos.enumerated() {
            var width = info.name.getWidth(font: defaultFont)
            width += buttAdditionalWidth
            if width + offset.x + xStep > fixedWidth {
                offset.y += buttHeight + heightStep
                offset.x = xStep
            }
            
            if idx < layoutButtons.count {
                layoutButtons[idx].frame = CGRect(x: offset.x,
                                                  y: offset.y,
                                                  width: width,
                                                  height: buttHeight)
            }
            
            offset.x += width + xStep
        }
        
        return offset.y + buttHeight + heightStep
    }
    
    weak var displayDelegate: SelectChartDisplayedViewDelegate?
    
    func display(groupData: ChartGroupData) {
        if groupData.data.count <= 1 {
            while buttons.count > 0 {
                buttons.popLast()?.removeFromSuperview()
            }
            return
        }
        
        while buttons.count > groupData.data.count {
            buttons.popLast()?.removeFromSuperview()
        }
        while buttons.count < groupData.data.count {
            buttons.append(generateButton())
        }
        
        for (item, butt) in zip(groupData.data, buttons) {
            butt.setTitle(item.name, for: .normal)
            butt.tintColor = item.color
            butt.setTitleColor(item.color, for: .normal)
            butt.isSelected = item.visible
        }
        
        _ = SelectChartDisplayedView.getHeightAndLayout(groupData: groupData, fixedWidth: bounds.size.width, layoutButtons: buttons)
    }
    
    func update(apereance: Apereance) {
        backgroundColor = apereance.bg
    }
    
    var titleColor: UIColor = .white {
        didSet {
            buttons.forEach({$0.setTitleColor(titleColor, for: .selected)})
        }
    }
    
    
    
    // MARK: private
    private lazy var checkmarkIcon = UIImage(named: "checkmark")
    private lazy var bgSelectedImage = UIImage(named: "butt_selected")?.resizableImage(withCapInsets: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)).withRenderingMode(.alwaysTemplate)
    private lazy var bgDeselectedImage = UIImage(named: "butt_deselected")?.resizableImage(withCapInsets: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)).withRenderingMode(.alwaysTemplate)
    private var buttons: [UIButton] = []
    private var buttHeight: CGFloat = 30.0
    
    private func generateButton() -> UIButton {
        let butt = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: buttHeight))
        butt.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        butt.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        butt.setTitleColor(titleColor, for: .selected)
        butt.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 7)
        butt.titleEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
        butt.setBackgroundImage(bgSelectedImage, for: .selected)
        butt.setBackgroundImage(bgDeselectedImage, for: .normal)
        butt.setImage(checkmarkIcon, for: .selected)
        butt.setImage(nil, for: .normal)
        butt.addTarget(self, action: #selector(itemButtonPressed(_:)), for: .touchUpInside)
        
        let long = UILongPressGestureRecognizer(target: self, action: #selector(itemButtonLongPressed(_:)))
        butt.addGestureRecognizer(long)
        
        addSubview(butt)
        return butt
    }
    
    @objc func itemButtonPressed(_ butt: UIButton) {
        guard let idx = buttons.firstIndex(of: butt) else {
            return
        }
        let display = !butt.isSelected
        let allow = displayDelegate?.chartDataRequestDisplayChange(index: idx, display: display)
        
        if allow ?? true {
            UIView.animate(withDuration: 0.2) {
                // я конечно могу и тут заморочится со всякими анимациями
                // но сон дороже
                butt.isSelected = display
                butt.layoutIfNeeded()
            }
        }
    }
    
    @objc func itemButtonLongPressed(_ press: UILongPressGestureRecognizer) {
        guard let butt = press.view as? UIButton,
            let idx = buttons.firstIndex(of: butt) else {
            return
        }
        for (i, b) in buttons.enumerated() {
            b.isSelected = (i == idx)
        }
        displayDelegate?.displayOnly(index: idx)
    }
}
