//
//  AttachedLabel.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 11/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class AttachedLabel: UILabel {

    var attachedValue: Float? {
        didSet {
            guard let val = attachedValue, val != oldValue else {
                return
            }
            text = valueFormatter?(val) ?? "\(Int(val))"
            sizeToFit()
        }
    }
    var attachedTime: Int64? {
        didSet {
            guard let val = attachedTime, val != oldValue else {
                return
            }
            text = timeFormatter?(val) ?? "\(val)"
            sizeToFit()
        }
    }

    var valueFormatter: ((Float)->(String))?
    var timeFormatter: ((Int64)->(String))?
    
    var used: Bool {
        return superview != nil
    }
    
    func unuse() {
        attachedValue = nil
        attachedTime = nil
        removeFromSuperview()
    }
}

class AttachedLabelAnimator {
    @discardableResult class func animateAppearDismiss(appear: [AttachedLabel], dismiss: [AttachedLabel], duration: Double) -> Cancelable {
        let startAppear: CGFloat = 0.0
        let appearDur: CGFloat = 0.8
        let startDismiss: CGFloat = 0.0
        let dismissDur: CGFloat = 0.5
        
        allAppearLabels.removeAll { dismiss.contains($0) }
        allAppearLabels.append(contentsOf: appear)
        
        let startAlphaDismiss = dismiss.first?.alpha ?? 1
        appear.forEach({$0.alpha = 0})
        let cancel = DisplayLinkAnimator.animate(duration: duration) { (progress) in
            
            let val = (progress - startAppear) / appearDur
            let alpha: CGFloat = min(1, max(0, val))
            for l in appear {
                if allAppearLabels.contains(l) { l.alpha = alpha }
            }
            
            if progress < 1 {
                let val = (progress - startDismiss) / dismissDur
                let alpha: CGFloat = max(0, min(1, startAlphaDismiss-val))
                dismiss.forEach({$0.alpha = alpha})
            } else {
                dismiss.forEach({$0.unuse()})
            }
        }
        
        return {
            allAppearLabels.removeAll(where: {appear.contains($0)})
            cancel()
        }
    }
    
    private static var allAppearLabels: [AttachedLabel] = []
}
