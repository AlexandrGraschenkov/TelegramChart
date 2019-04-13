//
//  ChartData.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit



enum ChartType {
    case line
    case stacked
    case percentage
}

class ChartGroupData: NSObject {
    let type: ChartType
    let scaled: Bool
    var data: [ChartData]
    
    init(type: ChartType, data: [ChartData], scaled: Bool = false) {
        self.scaled = (type == .line) && scaled
        self.type = type
        self.data = data
    }
    
    var itemsCount: Int {
        return data.first?.items.count ?? 0
    }
    
    func getMinTime() -> Int64 {
        return data.first?.items.first?.time ?? -1
    }
    
    func getMaxTime() -> Int64 {
        return data.first?.items.last?.time ?? -1
    }
    
    typealias CloseMode = ChartData.CloseMode
    func getClosestDate(date: Int64, mode: CloseMode = .close) -> (Int, Int64)? {
        return data.first?.getClosestDate(date: date, mode: mode)
    }
}

struct ChartData {
    
    init(color: UIColor, items: [Item], name: String? = nil) {
        self.color = color
        self.items = items
        self.name = name
        self.visible = true
    }
    
    struct Item {
        let time: Int64
        let value: Float
    }
    
    var items: [Item]
    var color: UIColor
    var name: String?
    var visible: Bool
    
    
    enum CloseMode {
        case close
        case ceil
        case floor
    }
    
    func getClosestDate(date: Int64, mode: CloseMode = .close) -> (Int, Int64)? {
        let count = items.count
        if count == 0 {
            return nil
        }
        
        let minTime = items.first!.time
        let maxTime = items.last!.time
        var percent = Float(date - minTime) / Float(maxTime - minTime)
        percent = max(min(percent, 1), 0)
        let percentIdx: Int
        switch mode {
        case .ceil:
            percentIdx = Int(ceil(percent * Float(count-1)))
        case .floor:
            percentIdx = Int(ceil(percent * Float(count-1)))
        case .close:
            percentIdx = Int(ceil(percent * Float(count-1)))
        }
        return (percentIdx, items[percentIdx].time)
    }
}


