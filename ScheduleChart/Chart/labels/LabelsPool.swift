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
    
    var color = Apereance.day.chartTextColor {
        didSet {
            labels.forEach({$0.color = color})
        }
    }
    
    func getUnused() -> AttachedLabel {
        var label: AttachedLabel! = labels.first(where: { (l) -> Bool in
            return !l.used
        })
        label = label ?? generate()
        label.alpha = 1
        label.customColor = nil
        label.attachedTime = nil
        label.attachedValue = nil
        label.rightAligment = false
        return label
    }
    
    func removeUnused() {
        for i in (0..<labels.count).reversed() {
            let label = labels[i]
            if !label.used {
                label.removeFromSuperview()
                labels.remove(at: i)
            }
        }
    }
    
    func removeAll() {
        for l in labels {
            l.removeFromSuperview()
        }
        labels.removeAll()
    }
    
    private func generate() -> AttachedLabel {
        let label = AttachedLabel(frame: CGRect(x: 0, y: 0, width: 30, height: 15))
        label.font = font
        label.color = color
        label.textAlignment = .center
//        label.isHidden = true
        labels.append(label)
//        print("Labels Pool:", labels.count)
//        label.backgroundColor = UIColor.yellow
        return label
    }
    
    private var labels: [AttachedLabel] = []
//    var getUnused() -> UIla
}
