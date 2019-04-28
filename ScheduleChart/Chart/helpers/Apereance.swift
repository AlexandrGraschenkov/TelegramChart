//
//  Apereance.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 14/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

enum Mode {
    case night
    case day
}

struct Apereance {

    static let day = Apereance(bg: UIColor.white,
                               scrollBg: UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00),
                               textColor: UIColor.black,
                               gridColor: UIColor(white: 0.65, alpha: 0.4),
                               chartTextColor: UIColor(white: 0.3, alpha: 0.7),
                               stackedOverlay: UIColor(white: 1, alpha: 0.5),
                               selectionChartOverlay: UIColor(red:0.95, green:0.96, blue:0.98, alpha:0.80),
                               infoBg: UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00),
                               infoTextColor: UIColor(red:0.43, green:0.43, blue:0.45, alpha:1.00),
                               navBarStyle: .default,
                               tableSeparator: UIColor(red:0.78, green:0.78, blue:0.80, alpha:1.00),
                               mode: .day)
    
    static let night = Apereance(bg: UIColor(red:0.14, green:0.18, blue:0.24, alpha:1.00),
                                 scrollBg: UIColor(red:0.10, green:0.13, blue:0.17, alpha:1.00),
                                 textColor: UIColor.white,
                                 gridColor: UIColor(white: 0.7, alpha: 0.5),
                                 chartTextColor: UIColor(white: 1, alpha: 0.7),
                                 stackedOverlay: UIColor(white: 1, alpha: 0.5),
                                 selectionChartOverlay: UIColor(red:0.10, green:0.13, blue:0.17, alpha:0.80),
                                 infoBg: UIColor(red:0.11, green:0.14, blue:0.18, alpha:1.00),
                                 infoTextColor: UIColor.white,
                                 navBarStyle: .black,
                                 tableSeparator: UIColor(red:0.07, green:0.10, blue:0.13, alpha:1.00),
                                 mode: .night)
    
    let bg: UIColor
    let scrollBg: UIColor
    let textColor: UIColor
    let gridColor: UIColor
    let chartTextColor: UIColor
    let stackedOverlay: UIColor
    let selectionChartOverlay: UIColor
    let infoBg: UIColor
    let infoTextColor: UIColor
    let navBarStyle: UIBarStyle
    let tableSeparator: UIColor
    let mode: Mode
    
}

private extension UIColor {
    convenience init(rgb: Int, alpha: CGFloat = 1.0) {
        let red = (rgb >> 16) & 0xFF
        let green = (rgb >> 8) & 0xFF
        let blue = rgb & 0xFF
        
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}
