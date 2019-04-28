//
//  ChartDataParser.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 12/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

extension ChartGroupData {
    static func readDictionary(dic: [String: Any]) -> ChartGroupData {
        guard let columns = dic["columns"] as? [[Any]],
            let types = dic["types"] as? [String: String],
            let names = dic["names"] as? [String: String],
            let colors = dic["colors"] as? [String: String] else {
                return ChartGroupData(type: .line, data: [], scaled: false)
        }
        
        if columns.count != types.count || columns.count == 0 {
            return ChartGroupData(type: .line, data: [], scaled: false)
        }
        if !columns.allSatisfy({$0.count == columns[0].count }) {
            return ChartGroupData(type: .line, data: [], scaled: false)
        }
        
        let keys: [String] = columns.map({$0[0] as! String})
        let values: [[Int64]] = columns.map({Array($0[1...]) as! [Int64]})
        guard let xAxisKey = types.first(where: {$0.value == "x"})?.key,
            let xAxisIdx = keys.firstIndex(of: xAxisKey) else {
                return ChartGroupData(type: .line, data: [], scaled: false)
        }
        
        var data: [ChartData] = []
        for i in 0..<keys.count {
            if keys[i] == xAxisKey { continue }
            var items = zip(values[xAxisIdx], values[i]).map{ChartData.Item(time: $0, value: Float($1))}
            items.sort(by: {$0.time < $1.time})
            
            guard let colorStr = colors[keys[i]],
                let color = UIColor(hex: colorStr) else {
                    continue
            }
            
            let name = names[keys[i]]
            data.append(ChartData(color: color, items: items, name: name))
        }
        
        var type = ChartType.line
//        if (dic["stacked"] as? Bool) ?? false {
//            type = .stacked
//            if (dic["percentage"] as? Bool) ?? false {
//                type = .percentage
//            }
//        }
        for t in types {
            if t.value == "x" { continue }
            switch t.value {
            case "line":
                type = .line
            case "bar": // 
                type = .stacked
            case "area":
                type = .percentage
            default:
                break
            }
        }
        let scaled = (dic["y_scaled"] as? Bool) ?? false
        
        return ChartGroupData(type: type, data: data, scaled: scaled)
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

