//
//  SelectionBehavior.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 14/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class SelectionDisplayBehavior: NSObject {
    
    var needShowCircles: Bool = false
    
    init(display: BaseDisplay) {
        self.display = display
    }
    
    func selectDate(date: Int64, transform: matrix_float3x3) {
        let transform = updateTransform(transform)
        generateSelectLineIfNeeded()
        selectionLine.isHidden = false
        let dateDivided = Float(date) / display.timeDivider
        let xPos = matrix_multiply(transform, vector_float3(dateDivided, 0, 1)).x
        selectionLine.center.x = CGFloat(xPos)
        
        if needShowCircles {
            showCircles(date: date, transform: transform)
        }
    }
    
    func deselect() {
        selectionLine.isHidden = true
        selectionCircles.forEach({$0.removeFromSuperlayer()})
    }
    
    private weak var display: BaseDisplay!
    private var selectionLine: UIView!
    private var selectionCircles: [CAShapeLayer] = []
    
    private func updateTransform(_ t: matrix_float3x3) -> matrix_float3x3 {
        let scale = Float(UIScreen.main.scale)
        let height = Float(display.view.bounds.height)
        let preMat = matrix_from_rows(vector_float3(1/scale, 0, 0),
                                      vector_float3(0, -1/scale, height),
                                      vector_float3(0, 0, 0))
        return matrix_multiply(preMat, t)
    }
    
    private func generateCircle() -> CAShapeLayer {
        let shape = ShapeLayer()
        shape.path = CGPath(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6), transform: nil)
        let fill = display.view.clearColor
        shape.fillColor = UIColor(red: CGFloat(fill.red),
                                  green: CGFloat(fill.green),
                                  blue: CGFloat(fill.blue),
                                  alpha: 1.0).cgColor
        shape.strokeColor = UIColor.red.cgColor
        shape.lineWidth = 2.0
        return shape
    }
    
    private func generateSelectLineIfNeeded() {
        if selectionLine != nil { return }
        let y = display.lastDisplayRect.origin.y
        let height = display.lastDisplayRect.height
        selectionLine = UIView(frame: CGRect(x: 0, y: y, width: 2/UIScreen.main.scale, height: height))
        selectionLine.backgroundColor = UIColor(white: 0.6, alpha: 0.6)
        selectionLine.isHidden = true
        display.view.addSubview(selectionLine)
    }
    
    private func generateCircles() {
        guard let data = display.data?.data else {
            return
        }
        if selectionCircles.count == data.count { return }
        
        while selectionCircles.count < data.count {
            let c = generateCircle()
            c.strokeColor = data[selectionCircles.count].color.cgColor
            selectionCircles.append(c)
        }
    }
    
    private func showCircles(date: Int64, transform: matrix_float3x3) {
        guard let groupData = display.data,
            let (idx, _) = groupData.getClosestDate(date: date) else {
            return
        }
        
        generateCircles()
        selectionCircles.forEach({display.view.layer.addSublayer($0)})
        
        let dateDivided = Float(date) / display.timeDivider
        for (i, (c, d)) in zip(selectionCircles, groupData.data).enumerated() {
            let scale = i < display.view.customScale.count ? display.view.customScale[i] : 1
            let val = d.items[idx].value
            var pos = vector_float3(dateDivided, scale * val, 1)
            pos = matrix_multiply(transform, pos)
            c.position = CGPoint(x: CGFloat(pos.x),
                                 y: CGFloat(pos.y))
        }
    }
}
