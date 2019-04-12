//
//  DataPreparer.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 11/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class DataPreparer: NSObject {
    
    enum GroupMode {
        case none, stacked, percentage
    }
    
    static func prepare(data:[ChartData], visiblePercent: [CGFloat], timeDivider: Float, mode: GroupMode, reduceCount: Int = 0) -> [[[vector_float2]]] {
        var result: [[vector_float2]] = []
        result.reserveCapacity(data.count)
        
        for d in data {
            var vec: [vector_float2] = []
            vec.reserveCapacity(d.items.count)
            
            for item in d.items {
                let time = Float(item.time) / timeDivider
                vec.append(vector_float2(time, item.value))
            }
            result.append(vec)
        }
        
        if mode != .none {
            for i in 0..<result.count {
                let percent = Float(visiblePercent[i])
                if percent < 1 {
                    for ii in 0..<result[i].count {
                        result[i][ii][1] *= percent
                    }
                }
            }
        }
        
        var resultReduced: [[[vector_float2]]] = [result]
        
        for _ in 0..<reduceCount {
            var result = resultReduced.last!
            for ii in 0..<result.count {
                result[ii] = reduce(data: result[ii])
            }
            resultReduced.append(result)
        }
        
        resultReduced = resultReduced.map{group(data:$0, mode: mode)}
        
        return resultReduced
    }
    
    static func group(data: [[vector_float2]], mode: GroupMode) -> [[vector_float2]] {
        let elemsCount = data.first?.count ?? 0
        var data = data
        switch mode {
        case .stacked:
            for i in 1..<data.count {
                for ii in 0..<elemsCount {
                    data[i][ii][1] += data[i-1][ii][1]
                }
            }
        case .percentage:
            for ii in 0..<elemsCount {
                var total: Float = 0
                for i in 0..<data.count {
                    total += data[i][ii][1]
                    if i > 0 {
                        data[i][ii][1] += data[i-1][ii][1]
                    }
                }
                total /= 100.0
                for i in 0..<data.count {
                    data[i][ii][1] /= total
                }
            }
        case .none:
            break
        }
        return data
    }
    
    static func reduce(data: [vector_float2]) -> [vector_float2] {
        if data.count <= 4 {
            return data
        }
        
        let elemsCount = data.count
        var result: [vector_float2] = []
        var data = data
        
        let timeOffset = (data[1][0] - data[0][0]) * 0.5
        for i in stride(from: 0, to: elemsCount, by: 4) {
            if elemsCount-i >= 3 {
                let toIdx = min(i+4, elemsCount)
                let (maxIdx, minIdx) = maxMinIdx(data: data[i..<toIdx])
                let arr: [Int] = maxIdx < minIdx ? [maxIdx, minIdx] : [minIdx, maxIdx]
                result.append(vector_float2(data[i][0] + timeOffset,
                                            data[arr[0]][1]))
                
                result.append(vector_float2(data[i+2][0]+timeOffset,
                                            data[arr[1]][1]))
            } else {
                result.append(vector_float2(data[i][0]+timeOffset,
                                            data[i][1]))
            }
        }
        return result
    }
    
    static func maxMinIdx(data: ArraySlice<vector_float2>) -> (Int, Int) {
        var maxIdx: Int = 0
        var minIdx: Int = 0
        let o = data.startIndex // https://stackoverflow.com/a/36251971/820795
        for idx in 1..<data.count {
            if data[idx+o][1] > data[maxIdx+o][1] {
                maxIdx = idx
            }
            if data[idx+o][1] < data[minIdx+o][1] {
                minIdx = idx
            }
        }
        return (maxIdx+o, minIdx+o)
    }
}
