//
//  LabelsPool.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 11/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class LabelsPool: NSObject {

    var font = UIFont.systemFont(ofSize: 12) {
        didSet {
            labels.forEach({$0.font = font})
        }
    }
    
    var color = UIColor(white: 0.4, alpha: 1.0) {
        didSet {
            labels.forEach({$0.textColor = color})
        }
    }
    
    func getUnused() -> AttachedLabel {
        let label = labels.first(where: { (l) -> Bool in
            return !l.isUsed
        })
        label?.alpha = 1
        label?.isHidden = false
        label?.attachedTime = nil
        label?.attachedValue = nil
        return label ?? generate()
    }
    
    func removeUnused() {
        for i in (0..<labels.count).reversed() {
            let label = labels[i]
            if !label.isUsed {
                label.removeFromSuperview()
                labels.remove(at: i)
            }
        }
    }
    
    private func generate() -> AttachedLabel {
        let label = AttachedLabel(frame: CGRect(x: 0, y: 0, width: 30, height: 15))
        label.font = font
        label.textColor = color
//        label.backgroundColor = UIColor.yellow
        return label
    }
    
    private var labels: [AttachedLabel] = []
//    var getUnused() -> UIla
}
