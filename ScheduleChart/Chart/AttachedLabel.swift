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
            if attachedValue == nil || oldValue == attachedValue {
                return
            }
            text = "\(Int(attachedValue!))"
            sizeToFit()
        }
    }
    var attachedTime: Int64?

    var isUsed: Bool {
        return superview != nil && alpha != 0 && !isHidden
    }
}
