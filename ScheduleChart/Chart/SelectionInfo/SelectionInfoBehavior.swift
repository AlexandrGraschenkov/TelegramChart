//
//  SelectionInfoBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 14/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit


// TODO: this classes `net` is dirty
class SelectionInfoBehavior {

    init(chart: ChartView) {
        self.chart = chart
        
        // it's really bad =( but when I try it in displayers, I have sync problem with views
        chart.onMinMaxValueAnimChange = { [weak self] in
            guard let `self` = self else { return }
            if !self.isDisplayed || self.lastSelectionDate == 0 { return }
            
            self.selectionDisplay.selectDate(date: self.lastSelectionDate, transform: self.chart.calculateTransform())
        }
    }
    
    var onTapClosure: (()->())?
    var showLineSelection: Bool = true
    var showCirclesOnSelection: Bool = true
    lazy var selectionDisplay = SelectionDisplayBehavior(chart: self.chart)
    private(set) var lastSelectionDate: Int64 = 0
    private(set) var isDisplayed: Bool = false
    var bgColor: UIColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00) {
        didSet {
            infoView.bgColor = bgColor
        }
    }
    
    func update(apereance: Apereance) {
        bgColor = apereance.infoBg
        infoView.textColor = apereance.infoTextColor
        selectionDisplay.update(apereance: apereance)
    }
    
    func dismissSelectedDate(animated: Bool) {
        if !isDisplayed { return }
        chart.selectedDate = nil
        selectionDisplay.deselect()
        if !animated {
            infoView.removeFromSuperview()
            isDisplayed = false
            lastSelectionDate = 0
            return
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
            self.infoView.alpha = 0
        }, completion: {finished in
            if finished {
                self.infoView.removeFromSuperview()
                self.isDisplayed = false
                self.lastSelectionDate = 0
            }
        })
    }
    
    func updateInfoFrame(dataUpdated: [ChartData]?) {
        if !isDisplayed || lastSelectionDate == 0 { return }
        
        updateInfoSelectedDate(date: lastSelectionDate, data: dataUpdated ?? [], forceUpdateContent: dataUpdated != nil)
    }
    
    func updateInfoSelectedDate(date: Int64, data: [ChartData], forceUpdateContent: Bool = false) {
        isDisplayed = true
        var infoAdded = false
        if infoView.superview == nil {
            chart.addSubview(infoView)
            infoAdded = true
        }
        infoView.onTapClosure = onTapClosure
        
        if lastSelectionDate != date || forceUpdateContent {
            // content
            if lastSelectionDate != date {
                lastSelectionDate = date
                chart.selectedDate = date
            }
            let displayTotal = (chart.data!.type == .stacked)
            let displayPercent = (chart.data!.type == .percentage)
            infoView.update(data: data, time: date, displayTotal: displayTotal, displayPercent: displayPercent)
            infoView.alpha = 1
        }
        
        // pose
        let pixelScale = UIScreen.main.scale
        let centerX = round(chart.getXPos(date: date) * pixelScale) / pixelScale
        let isAnimating = infoView.layer.animationKeys() != nil
        if !isAnimating && (centerX < 0 || centerX >= chart.bounds.width) {
            dismissSelectedDate(animated: true)
        }
        selectionDisplay.selectDate(date: date, transform: chart.calculateTransform())
        
        infoView.center = CGPoint(x: centerX, y: 35)
        updateAnchorPoint(animated: !infoAdded)
    }
    
    
    // mark: private
    private weak var chart: ChartView!
    lazy var infoView: SelctionInfoView = createSelectionInfoView()
    private var selectInfoViewOnRight: Bool = true
    
    
    private func createSelectionInfoView() -> SelctionInfoView {
        let view = SelctionInfoView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.bgColor = bgColor
        let anchor: CGPoint
        if selectInfoViewOnRight {
            anchor = CGPoint(x: -5 / view.fixedWidth, y: 0)
        } else {
            anchor = CGPoint(x: 1 + 5 / view.fixedWidth, y: 0)
        }
        view.layer.anchorPoint = anchor
        return view
    }
    
    private func updateAnchorPoint(animated: Bool) {
        let hitBounds = chart.bounds.insetBy(dx: 5, dy: 0)
        var newDisplayOnRight: Bool?
        if hitBounds.minX > infoView.frame.minX {
            newDisplayOnRight = true
        }
        if hitBounds.maxX < infoView.frame.maxX {
            newDisplayOnRight = false
        }
        guard let onRight = newDisplayOnRight, onRight != selectInfoViewOnRight else {
            return
        }
        
        selectInfoViewOnRight = onRight
        let anchor: CGPoint
        if selectInfoViewOnRight {
            anchor = CGPoint(x: -5 / infoView.fixedWidth, y: 0)
        } else {
            anchor = CGPoint(x: 1 + 5 / infoView.fixedWidth, y: 0)
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                self.infoView.layer.anchorPoint = anchor
            }, completion: nil)
        } else {
            infoView.layer.anchorPoint = anchor
        }
    }
}
