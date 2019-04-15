//
//  ChartSelectionView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 20/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

protocol ChartSelectionViewDelegate: class {
    func selectionRangeChanged(_ selctionView: ChartSelectionView, range: ChartSelectionView.Range)
}

class ChartSelectionView: UIView {

    struct Range: Equatable {
        var from: CGFloat
        var to: CGFloat
        static func == (lhs: Range, rhs: Range) -> Bool {
            return lhs.from == rhs.from && lhs.to == rhs.to
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var range: Range = Range(from: 0, to: 1) {
        didSet {
            if oldValue == range { return }
            setNeedsLayout(); layoutIfNeeded()
        }
    }
    var minRangeDist: CGFloat = 0.1
    weak var delegate: ChartSelectionViewDelegate?
    
    
    func update(apereance: Apereance) {
        let imgName: String
        switch apereance.mode {
        case .day:
            imgName = "white_selector"
        case .night:
            imgName = "dark_selector"
        }
        selectionImgView.image = UIImage(named: imgName)?.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 13, bottom: 3, right: 13))
        cornerBorders.tintColor = apereance.bg
        
        rightOverlay.backgroundColor = apereance.selectionChartOverlay
        leftOverlay.backgroundColor = apereance.selectionChartOverlay
    }
    
    func setupGestures(view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        self.panGesture = panGesture
    }
    
    
    // MARK: private
    private var leftOverlay: UIView!
    private var rightOverlay: UIView!
    private var selectionImgView: UIImageView!
    private var cornerBorders: UIImageView!
    private var panStartRange: Range = Range(from: 0, to: 1)
    private var panGesture: UIPanGestureRecognizer?
    
    private enum PanSide {
        case left, right, center
    }
    private var panSide: PanSide = .center
    
    private func setupViews() {
        let autoresize: UIView.AutoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleRightMargin]
        clipsToBounds = false
        
        leftOverlay = UIView(frame: bounds)
        addSubview(leftOverlay)
        
        rightOverlay = UIView(frame: bounds)
        addSubview(rightOverlay)
        
        cornerBorders = UIImageView(image: UIImage(named: "selection_border_mask")?.resizableImage(withCapInsets: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)).withRenderingMode(.alwaysTemplate))
        cornerBorders.frame = bounds
        cornerBorders.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        selectionImgView = UIImageView()
        selectionImgView.autoresizingMask = autoresize
        addSubview(cornerBorders)
        addSubview(selectionImgView)
        
        update(apereance: .day)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftX = range.from * bounds.width
        let righX = range.to * bounds.width
        let offset = CGFloat(3)
        
        leftOverlay.frame = CGRect(x: 0, y: 0, width: leftX+offset, height: bounds.height)
        rightOverlay.frame = CGRect(x: righX-offset, y: 0, width: bounds.width-righX+offset, height: bounds.height)
        selectionImgView.frame = CGRect(x: leftX, y: 0, width: righX-leftX, height: bounds.height).insetBy(dx: -1, dy: -2)
    }

    
    @objc func onPan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            panBegan(pan: pan)
        case .cancelled:
            break
        default:
            panChanged(pan: pan)
        }
    }
    
    private func panBegan(pan: UIPanGestureRecognizer) {
        panStartRange = range
        let leftX = range.from * bounds.width + 2.5
        let righX = range.to * bounds.width - 2.5
        let loc = pan.location(in: self)
        let translate = pan.translation(in: self)
        
        let pos = CGPoint(x: loc.x - translate.x, y: loc.y - translate.y)
        let leftDist = abs(leftX - pos.x)
        let rightDist = abs(righX - pos.x)
        if leftDist < rightDist && leftDist < 20 {
            panSide = .left
        } else if rightDist < 20 {
            panSide = .right
        } else if leftX < pos.x && pos.x < righX {
            panSide = .center
        } else {
            pan.isEnabled = false
            pan.isEnabled = true
        }
    }
    
    private func panChanged(pan: UIPanGestureRecognizer) {
        let x = pan.translation(in: self).x
        let percentOffset = x / bounds.width
        var newRange = range
        
        if panSide == .center || panSide == .left {
            newRange.from = panStartRange.from + percentOffset
            newRange.from = max(0, newRange.from)
        }
        if panSide == .center || panSide == .right {
            newRange.to = panStartRange.to + percentOffset
            newRange.to = min(1, newRange.to)
        }
        
        let minDist = panSide == .center ? (panStartRange.to - panStartRange.from) : minRangeDist
        newRange = fixMinRange(newRange, side: panSide, minDist: minDist)
        updateRange(newRange: newRange)
    }
    
    private func fixMinRange(_ range: Range, side: PanSide, minDist: CGFloat) -> Range {
        var range = range
        if range.from + minDist > range.to {
            if side == .left || range.from < 0 {
                range.to = min(1, range.from + minDist)
                range.from = min(range.from, range.to - minDist)
            } else {
                range.from = max(0, range.to - minDist)
                range.to = max(range.to, range.from + minDist)
            }
        }
        return range
    }
    
    private func updateRange(newRange: Range) {
        if newRange == range { return }
        range = newRange
        delegate?.selectionRangeChanged(self, range: range)
    }
}

extension ChartSelectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture && checkRect(g: gestureRecognizer) {
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
        
        if !checkRect(g: g) {
            return false
        }
        
        if let pan = g as? UIPanGestureRecognizer {
            let t = pan.translation(in: self)
            if abs(t.y) > abs(t.x) {
                return false
            }
        }
        return true
    }
    
    private func checkRect(g: UIGestureRecognizer) -> Bool {
        let expandFrame = frame.insetBy(dx: -15, dy: -4)
        return expandFrame.contains(panGesture!.location(in: self))
    }
}
