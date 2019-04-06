//
//  LineController.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 05/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class LineController: NSObject {
    typealias RangeI = ChartView.RangeI
    
    var layers: [CAShapeLayer] = []
    var data: [ChartData] = []
    var maxValue: Float = 200
    var displayRange: RangeI = RangeI(from: 0, to: 0)
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect, force: Bool) {
        
    }
}
