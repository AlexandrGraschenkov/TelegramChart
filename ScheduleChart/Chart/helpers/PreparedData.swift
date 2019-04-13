//
//  PreparedData.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 13/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class PreparedData: NSObject {
    
    static let maxReduceCount: Int = 1
    static let timeDivider: Float = 100_000
    var data: [[[vector_float2]]] = []
    
    
    init(groupData: ChartGroupData) {
        super.init()
        
        let visible = Array(repeating: CGFloat(1), count: groupData.data.count)
//        let mode: DataPreparer.GroupMode
//        switch groupData.type {
//        case .line:
//            mode = .none
//        case .percentage:
//            mode = .percentage
//        case .stacked:
//            mode = .stacked
//        }
        data = DataPreparer.prepare(data: groupData.data, visiblePercent: visible, timeDivider: PreparedData.timeDivider, mode: .none, reduceCount: PreparedData.maxReduceCount)
    }
}
