//
//  AxesDrawer.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class AxesDrawer: NSObject {
    var showHorisontal: Bool = true
    var showVertical: Bool = true
    
    func getAxesInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: showVertical ? 20 : 0,
                            bottom: showHorisontal ? 20 : 0,
                            right: 0)
    }
    
    func draw() {
        
    }
}
