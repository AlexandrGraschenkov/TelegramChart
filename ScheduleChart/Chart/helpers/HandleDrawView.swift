//
//  HandleDrawView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 07/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class HandleDrawView: UIView {
    var onDraw: (()->())?
    override func draw(_ rect: CGRect) {
        onDraw?()
    }
}
