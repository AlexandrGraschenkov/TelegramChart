//
//  BaseDisplay.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 08/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

extension CGAffineTransform {
    func getMatrix() -> matrix_float3x3 {
        let r1 = simd_float3(Float(a) , Float(b) , 0)
        let r2 = simd_float3(Float(c) , Float(d) , 0)
        let r3 = simd_float3(Float(tx) , Float(ty) , 1)
        return matrix_float3x3(columns: (r1, r2, r3))
    }
}

class BaseDisplay: NSObject {
    enum DataGroping {
        case none, stacked, percentage
    }
    
    typealias RangeI = ChartView.RangeI
    var view: MetalChartView
    var chartDataCount: Int = 0
    var chartItemsCount: Int = 0
    var data: [ChartData] = [] {
        didSet { dataUpdated() }
    }
    var dataAlpha: [CGFloat] = []
    let timeDivider: CGFloat = 100_000
    var grooping: DataGroping = .none
    var showGrid: Bool = true // false for PieChart
    
    init(view: MetalChartView) {
        self.view = view
        super.init()
    }
    
    func update(maxValue: Float, displayRange: RangeI, rect: CGRect) {
        let t = calculateTransform(maxValue: maxValue, displayRange: displayRange, rect: rect)
        view.globalParams.transform = t.getMatrix()
    }
    
    func dataUpdated() {
        assert(false, "override it")
    }
    
    
    func display(renderEncoder: MTLRenderCommandEncoder) {
        assert(false, "override it")
    }
    
    func calculateTransform(maxValue: Float, displayRange: RangeI, rect: CGRect) -> CGAffineTransform {
        let fromTime = CGFloat(displayRange.from)/timeDivider
        let toTime = CGFloat(displayRange.to)/timeDivider
        let maxValue = CGFloat(maxValue)
        
        var t: CGAffineTransform = .identity
        let scaleX = rect.width / (toTime - fromTime)
        t = t.scaledBy(x: UIScreen.main.scale, y: UIScreen.main.scale)
        t = t.translatedBy(x: rect.minX, y: view.bounds.height - rect.maxY)
        t = t.scaledBy(x: scaleX, y: rect.height / maxValue)
        t = t.translatedBy(x: -fromTime, y: 0)
        return t
    }
}
