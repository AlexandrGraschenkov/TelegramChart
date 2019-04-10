//
//  ChartData.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit


struct ChartData {

    static func generateData(dic: [String: Any]) -> [ChartData] {
        guard let columns = dic["columns"] as? [[Any]],
            let types = dic["types"] as? [String: String],
            let names = dic["names"] as? [String: String],
            let colors = dic["colors"] as? [String: String] else {
            return []
        }
        
        if columns.count != types.count || columns.count == 0 {
            return []
        }
        if !columns.allSatisfy({$0.count == columns[0].count }) {
            return []
        }
        
        let keys: [String] = columns.map({$0[0] as! String})
        let values: [[Int64]] = columns.map({Array($0[1...]) as! [Int64]})
        guard let xAxisKey = types.first(where: {$0.value == "x"})?.key,
            let xAxisIdx = keys.firstIndex(of: xAxisKey) else {
            return []
        }
        
        var result: [ChartData] = []
        for i in 0..<keys.count {
            if keys[i] == xAxisKey { continue }
            var items = zip(values[xAxisIdx], values[i]).map{Item(time: $0, value: Float($1))}
            items.sort(by: {$0.time < $1.time})
            
            guard let colorStr = colors[keys[i]],
                let color = UIColor(hex: colorStr) else {
                continue
            }
            
            let name = names[keys[i]]
            result.append(ChartData(color: color, items: items, name: name))
        }
        return result
    }
    
    init(color: UIColor, items: [Item], name: String? = nil) {
        self.color = color
        self.items = items
        self.name = name
    }
    
    struct Item {
        let time: Int64
        let value: Float
    }
    
    var items: [Item]
    var color: UIColor
    var name: String?
    
    func ceilIndex(time: Int64) -> Int? {
        if items.count < 2 { return nil }
        let percent = Float(time - items[0].time)  /
                      Float(items.last!.time - items[0].time)
        let idx = Int(ceil(percent * Float(items.count-1)))
        return idx
//        while idx > 0 && idx < items.count && time <= items[idx].time {
//
//        }
    }
    
    func floorIndex(time: Int64) -> Int? {
        if items.count < 2 { return nil }
        let percent = Float(time - items[0].time)  /
            Float(items.last!.time - items[0].time)
        let idx = Int(floor(percent * Float(items.count)))
        return idx
    }
}


private extension UIColor {
    
    convenience init?(hex: String, alpha: CGFloat = 1) {
        if hex[hex.startIndex] != "#" {
            return nil
        }
        
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1  // skip #
        
        var rgb: UInt32 = 0
        scanner.scanHexInt32(&rgb)
        
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgb &   0xFF00) >>  8)/255.0,
            blue:  CGFloat((rgb &     0xFF)      )/255.0,
            alpha: alpha)
    }
}
