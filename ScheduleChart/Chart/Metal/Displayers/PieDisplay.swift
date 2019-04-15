//
//  PieDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 15/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class PieDisplay: BaseDisplay {

    var shapes: [CAShapeLayer] = []
    
    override init(view: MetalChartView, device: MTLDevice, reuseBuffers: MetalBuffer?) {
        super.init(view: view, device: device, reuseBuffers: nil)
        
        
    }
    
    override func dataUpdated() {
        shapes.forEach({$0.removeFromSuperlayer()})
//        guard let 
    }
}
