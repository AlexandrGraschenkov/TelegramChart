//
//  DataMaxValCalculator.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 21/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class DataMaxValCalculator: NSObject {
    static func getMaxValue(_ data: [ChartData], fromTime: Int64? = nil, toTime: Int64? = nil, stacked: Bool = false, dividableBy: Int = 5) -> Float {
        if data.count == 0 || data[0].items.count == 0 {
            return 0
        }
        
        let fromTime: Int64 = fromTime ?? data[0].items.first!.time
        let toTime: Int64 = toTime ?? data[0].items.last!.time
        var maxVal: Float = 0
        if stacked {
            for ii in 0..<data[0].items.count {
                let sumVal: Float = data.reduce(0, {$0+$1.items[ii].value})
                if sumVal > maxVal {
                    maxVal = sumVal
                }
            }
        } else {
            for d in data {
                for item in d.items {
                    if fromTime <= item.time && item.time <= toTime {
                        if maxVal < item.value {
                            maxVal = item.value
                        }
                    }
                }
            }
        }
        
        let threshold = maxVal * 1.3
        let dividable = Float(dividableBy)

        
        var tenDividable = dividable
        var topVal = ceil(maxVal / tenDividable) * tenDividable
        while topVal < threshold {
            tenDividable *= 10
            topVal = ceil(maxVal / tenDividable) * tenDividable
        }
        tenDividable /= 10
        topVal = ceil(maxVal / tenDividable) * tenDividable
        
        return topVal
    }
}
