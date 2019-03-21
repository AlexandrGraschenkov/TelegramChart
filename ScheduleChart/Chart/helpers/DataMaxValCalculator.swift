//
//  DataMaxValCalculator.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 21/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class DataMaxValCalculator: NSObject {
    static func getMaxValue(_ data: [ChartData], fromTime: Int64? = nil, toTime: Int64? = nil) -> Float {
        if data.count == 0 || data[0].items.count == 0 {
            return 0
        }
        
        let fromTime: Int64 = fromTime ?? data[0].items.first!.time
        let toTime: Int64 = fromTime ?? data[0].items.last!.time
        var maxVal: Float = 0
        for d in data {
            for item in d.items {
                
            }
        }
        return maxVal
    }
}
