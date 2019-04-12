//
//  StringCachedWidthCalculator.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 12/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit


private var cache: [String: CGFloat] = [:]

extension String {
    func getWidth(font: UIFont) -> CGFloat {
        var key = font.familyName + font.fontName + "\(font.pointSize)" + "|||"
        key += self
        if let width = cache[key] {
            return width
        }
        
        var width = (self as NSString).size(withAttributes: [NSAttributedString.Key.font : font]).width
        width = ceil(width)
        cache[key] = width
        return width
    }
}
