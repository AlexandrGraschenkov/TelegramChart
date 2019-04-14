//
//  SelctionInfoView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 24/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class SelctionInfoView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    let fixedWidth: CGFloat = 130
    
    var textColor: UIColor = UIColor(white: 0.4, alpha: 1.0) {
        didSet {
            dateLabel.textColor = textColor
            for lab in titleLabels {
                lab.textColor = textColor
            }
            if lastDisplayAll {
                valLabels.last?.textColor = textColor
            }
        }
    }
    
    var bgColor: UIColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00) {
        didSet {
            bg.tintColor = bgColor
        }
    }
    
    func update(data: [ChartData], time: Int64, displayTotal: Bool = false) {
        if data.count == 0 { return }
        guard let idx = data[0].getClosestDate(date: time, mode: .ceil)?.0 else { return }
        
        lastDisplayAll = displayTotal
        dateLabel.text = dateFormatter(time)
        
        var values: [ColorVal] = data.map{ColorVal(val: $0.items[idx].value, color: $0.color, title: $0.name)}
        if displayTotal {
            let sumVal = data.reduce(0, { $0 + $1.items[idx].value })
            values.append(ColorVal(val: sumVal, color: textColor, title: "All"))
        }
        displayValues(values)
        displayTitles(values)
        layoutAndResize()
    }
    
    // MARK: private
    private var valLabels: [UILabel] = []
    private var titleLabels: [UILabel] = []
    private var dateLabel: UILabel!
    private var bg: UIImageView!
    private var lastDisplayAll: Bool = false

    private lazy var valueFormatter: (Float)->(String) = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        return { (val: Float) -> String in
            return formatter.string(from: NSNumber(value: val)) ?? ""
        }
    }()
    
    private lazy var dateFormatter: (Int64)->(String) = {
        let df = DateFormatter()
        df.dateFormat = "EEE, d MMM yyyy"
        return { (time: Int64) -> String in
            return df.string(from: Date(timeIntervalSince1970: TimeInterval(time) / 1000.0))
        }
    }()
    
    private struct ColorVal {
        let val: Float
        let color: UIColor
        let title: String?
    }
    
    // MARK: methods
    
    private func setup() {
        bg = UIImageView(frame: bounds)
        bg.image = UIImage(named: "selection_info_bg")?.resizableImage(withCapInsets: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)).withRenderingMode(.alwaysTemplate)
        bg.tintColor = bgColor
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(bg)
        
        dateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        dateLabel.textColor = textColor
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        dateLabel.textAlignment = .left
        addSubview(dateLabel)
    }
    
    private func displayValues(_ values: [ColorVal]) {
        while values.count > valLabels.count {
            valLabels.append(generateValueLabel())
        }
        while values.count < valLabels.count {
            valLabels.popLast()?.removeFromSuperview()
        }
        
        for (val, label) in zip(values, valLabels) {
            label.text = valueFormatter(val.val)
            label.textColor = val.color
        }
    }
    
    private func displayTitles(_ values: [ColorVal]) {
        let titlesIsSet = titleLabels.count == values.count
        while values.count > titleLabels.count {
            titleLabels.append(generateTitleLabel())
        }
        while values.count < titleLabels.count {
            titleLabels.popLast()?.removeFromSuperview()
        }
        
        if titlesIsSet { return }
        for (val, label) in zip(values, titleLabels) {
            label.text = val.title
            label.textColor = textColor
        }
    }
    
    private func generateValueLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .right
        addSubview(label)
        return label
    }
    
    private func generateTitleLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .left
        addSubview(label)
        return label
    }
    
    private func layoutAndResize() {
        let labelsHeight: CGFloat = 16
        let inset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        dateLabel.frame = CGRect(x: inset.left,
                                 y: inset.top,
                                 width: fixedWidth - (inset.left + inset.right),
                                 height: labelsHeight)
        
        var offset = CGPoint(x: inset.left, y: inset.top + 20)
        for (lab1, lab2) in zip(valLabels, titleLabels) {
            lab1.frame = CGRect(x: offset.x, y: offset.y, width: dateLabel.bounds.width, height: labelsHeight)
            lab2.frame = lab1.frame
            offset.y = lab1.frame.maxY
        }
        
        let height = offset.y + inset.bottom
        resizeTo(CGSize(width: fixedWidth, height: height))
    }
    
    private func resizeTo(_ newSize: CGSize) {
        frame = CGRect(x: frame.midX - newSize.width / 2.0,
                       y: frame.minY,
                       width: newSize.width,
                       height: newSize.height)
    }
}
