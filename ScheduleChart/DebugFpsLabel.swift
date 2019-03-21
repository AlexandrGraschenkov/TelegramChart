//
//  DebugFpsLabel.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class DebugFpsLabel: UILabel {

    var callTimes: [TimeInterval] = []
    var timer: Timer?
    var onPrevDrawCalled = false
    
    func startCapture() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
    }
    
    func stopCapture() {
        timer?.invalidate()
        timer = nil
    }
    
    func drawCalled() {
        callTimes.append(CFAbsoluteTimeGetCurrent())
        if callTimes.count > 10 {
            callTimes.remove(at: 0)
        }
        if !onPrevDrawCalled {
            updateLabel()
        }
        onPrevDrawCalled = !onPrevDrawCalled
    }

    @objc func updateLabel() {
        guard let last = callTimes.last,
            CFAbsoluteTimeGetCurrent() - last < 1.0 else {
            text = "-"
            callTimes.removeAll()
            return
        }
        
        if callTimes.count < 2 { return }
        
        let fps = Double(callTimes.count-1) / (callTimes.last! - callTimes.first!)
        text = NSString(format: "%.2lf", fps) as String
    }
}
