//
//  DataMaxValCalculator.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 21/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class DataMaxValCalculator: NSObject {
    static func getMinMaxValue(_ data: [ChartData], fromTime: Int64? = nil, toTime: Int64? = nil, stacked: Bool = false, withMinValue: Bool = false, dividableBy: Int = 5) -> (Float, Float) {
        if data.count == 0 || data[0].items.count == 0 {
            return (0, 0)
        }
        
        let fromTime: Int64 = fromTime ?? data[0].items.first!.time
        let toTime: Int64 = toTime ?? data[0].items.last!.time
        var maxVal: Float = 0
        var minVal: Float = -1
        if stacked {
            for ii in 0..<data[0].items.count {
                if fromTime > data[0].items[ii].time || data[0].items[ii].time > toTime {
                    continue
                }
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
                        if withMinValue && (minVal < 0 || minVal > item.value) {
                            minVal = item.value
                        }
                    }
                }
            }
        }
        minVal = max(minVal, 0)
        
        
        if !withMinValue {
            let topVal = selectOptimalMaxValue(maxVal: maxVal, dividableBy: dividableBy)
            return (0, topVal)
        }
        
        // revert upside down, and select by same algo
        let percent = (maxVal - minVal) / maxVal
        
        let fakeDividable = Int(Float(dividableBy) / percent)
        let topVal = selectOptimalMaxValue(maxVal: maxVal, dividableBy: fakeDividable)
        let fakeMaxVal = topVal - minVal
        let botVal = topVal - selectOptimalMaxValue(maxVal: fakeMaxVal, dividableBy: dividableBy)
//        botVal = (botVal - topVal) * (Float(dividableBy) / Float(dividableBy-1)) + topVal
        
        return (botVal, topVal)
    }
    
    private static func selectOptimalMaxValue(maxVal: Float, dividableBy: Int, maxThreshold: Float? = nil) -> Float {
        let maxThreshold = maxThreshold ?? maxVal * 1.3
        let dividable = Float(dividableBy)
        
        
        var tenDividable = dividable
        var topVal = ceil(maxVal / tenDividable) * tenDividable
        while topVal < maxThreshold {
            tenDividable *= 10
            topVal = ceil(maxVal / tenDividable) * tenDividable
        }
        tenDividable /= 10
        topVal = ceil(maxVal / tenDividable) * tenDividable
        
        return topVal
    }
}
