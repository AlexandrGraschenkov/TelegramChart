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
    
    var textColor: UIColor = UIColor(white: 0.4, alpha: 1.0) {
        didSet {
            dateLabel.textColor = textColor
            yearLabel.textColor = textColor
        }
    }
    
    var bgColor: UIColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00) {
        didSet {
            bg.tintColor = bgColor
        }
    }
    
    func update(data: [ChartData], time: Int64) {
        if data.count == 0 { return }
        guard let idx = data[0].getClosestDate(date: time, mode: .ceil)?.0 else { return }
        
        yearLabel.text = yearFormatter(time)
        dateLabel.text = dateFormatter(time)
        
        let values: [ColorVal] = data.map{ColorVal(val: $0.items[idx].value, color: $0.color)}
        displayValues(values)
        layoutAndResize()
    }
    
    // MARK: private
    private var valLabels: [UILabel] = []
    private var dateLabel: UILabel!
    private var yearLabel: UILabel!
    private var bg: UIImageView!

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
        df.dateFormat = "MMM dd"
        return { (time: Int64) -> String in
            return df.string(from: Date(timeIntervalSince1970: TimeInterval(time) / 1000.0))
        }
    }()
    
    private lazy var yearFormatter: (Int64)->(String) = {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        return { (time: Int64) -> String in
            return df.string(from: Date(timeIntervalSince1970: TimeInterval(time) / 1000.0))
        }
    }()
    
    private struct ColorVal {
        let val: Float
        let color: UIColor
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
        addSubview(dateLabel)
        
        yearLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        yearLabel.textColor = textColor
        yearLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        addSubview(yearLabel)
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
    
    private func generateValueLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .right
        addSubview(label)
        return label
    }
    
    private func layoutAndResize() {
        let labelsHeight: CGFloat = 16
        let inset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let largeSize = CGSize(width: 400, height: labelsHeight)
        dateLabel.frame = CGRect(x: inset.left,
                                 y: inset.top,
                                 width: dateLabel.sizeThatFits(largeSize).width,
                                 height: labelsHeight)
        yearLabel.frame = CGRect(x: inset.left,
                                 y: dateLabel.frame.maxY,
                                 width: dateLabel.sizeThatFits(largeSize).width,
                                 height: labelsHeight)
        let xValOffset = max(dateLabel.frame.maxX, yearLabel.frame.maxX)
        
        let maxValWidth: CGFloat = valLabels.reduce(0, {max($0, $1.sizeThatFits(largeSize).width)})
        var offset = CGPoint(x: xValOffset + 10, y: inset.top)
        for lab in valLabels {
            lab.frame = CGRect(x: offset.x, y: offset.y, width: maxValWidth, height: labelsHeight)
            offset.y = lab.frame.maxY
        }
        
        let width = (valLabels.first?.frame.maxX ?? xValOffset) + inset.right
        let height = max(offset.y, yearLabel.frame.maxY) + inset.bottom
        resizeTo(CGSize(width: width, height: height))
    }
    
    private func resizeTo(_ newSize: CGSize) {
        frame = CGRect(x: frame.midX - newSize.width / 2.0,
                       y: frame.minY,
                       width: newSize.width,
                       height: newSize.height)
    }
}
