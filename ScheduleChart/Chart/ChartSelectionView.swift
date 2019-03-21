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
    typealias Mode = ChartCopmosedView.Mode
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var range: Range = Range(from: 0, to: 1) {
        didSet {
            if oldValue == range { return }
            setNeedsLayout(); layoutIfNeeded()
            delegate?.selectionRangeChanged(self, range: range)
        }
    }
    var minRangeDist: CGFloat = 0.1
    var mode: Mode = .day
    weak var delegate: ChartSelectionViewDelegate?
    
    // mark: private
    private var leftOverlay: UIView!
    private var rightOverlay: UIView!
    private var selectionImgView: UIImageView!
    private var panStartRange: Range = Range(from: 0, to: 1)
    private var panGesture: UIPanGestureRecognizer?
    
    private enum PanSide {
        case left, right, center
    }
    private var panSide: PanSide = .center
    
    private func setupViews() {
        let autoresize: UIView.AutoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleRightMargin]
        
        leftOverlay = UIView(frame: bounds)
        addSubview(leftOverlay)
        
        rightOverlay = UIView(frame: bounds)
        addSubview(rightOverlay)
        
        selectionImgView = UIImageView(image: UIImage(named: "selection_area")?.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)))
        selectionImgView.autoresizingMask = autoresize
//        selectionImgView.backgroundColor = UIColor.red
        addSubview(selectionImgView)
        updateMode()
    }
    
    private func updateMode() {
        let overlayColor: UIColor
        switch mode {
        case .day:
            overlayColor = UIColor(red:0.95, green:0.96, blue:0.98, alpha:0.80)
        case .night:
            overlayColor = UIColor(red:0.10, green:0.13, blue:0.17, alpha:0.80)
        }
        rightOverlay.backgroundColor = overlayColor
        leftOverlay.backgroundColor = overlayColor
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        self.panGesture = panGesture
//        var s = superview
//        while s != nil && !(s is UITableView) {
//            s = s?.superview
//        }
//        print(s?.gestureRecognizers)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftX = range.from * bounds.width
        let righX = range.to * bounds.width
        
        leftOverlay.frame = CGRect(x: 0, y: 0, width: leftX, height: bounds.height)
        rightOverlay.frame = CGRect(x: righX, y: 0, width: bounds.width-righX, height: bounds.height)
        selectionImgView.frame = CGRect(x: leftX, y: 0, width: righX-leftX, height: bounds.height)
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
        range = newRange
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
}

extension ChartSelectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
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
        
        if let pan = g as? UIPanGestureRecognizer {
            let t = pan.translation(in: self)
            if abs(t.y) > abs(t.x) {
                return false
            }
        }
        return true
    }
}
