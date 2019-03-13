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
    
    var unused: Bool {
        guard let parent = superview else {
            return true
        }
        return alpha == 0 || isHidden || (!parent.bounds.intersects(frame) && alpha == 1)
    }
}
