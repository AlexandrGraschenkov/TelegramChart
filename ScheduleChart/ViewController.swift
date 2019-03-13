//
//  ViewController.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    @IBOutlet weak var chartView: ChartView!
    @IBOutlet weak var fpsLabel: DebugFpsLabel!
    var data1: [ChartData] = []
    var data2: [ChartData] = []
    var data3: [ChartData] = []
    var data4: [ChartData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let url = Bundle.main.url(forResource: "chart_data", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = obj as? [[String: Any]] {
            data1 = ChartData.generateData(dic: json[0])
            data2 = ChartData.generateData(dic: json[1])
            data3 = ChartData.generateData(dic: json[2])
            data4 = ChartData.generateData(dic: json[3])
        }
        
        chartView.data = data1
        chartView.onDrawDebug = fpsLabel.drawCalled
        fpsLabel.startCapture()
    }
    
    func generateData(count: Int, from: Float, to: Float, sinPower: Float? = nil) -> [Float] {
        var result: [Float] = []
        for i in 0..<count {
            var val = Float.random(in: from...to)
            if let p = sinPower {
                val += p * sin(Float(i) / 10)
            }
            result.append(val)
        }
        return result
    }
    
    var animIdx: Int = 0
    @IBAction func nightModePressed() {
        animIdx = (animIdx + 1) % 3
        let maxVal: Float = 200 + Float(animIdx) * 100
        chartView.animateMaxVal(val: maxVal)
//        _ = DisplayLinkAnimator.animate(duration: 2.0) { (percent) in
//            let dTime = self.chartView.dataMaxTime - self.chartView.dataMinTime
//            self.chartView.displayRange.to = Int64((1-(0.8 * percent)) * CGFloat(dTime)) + self.chartView.dataMinTime
//            self.chartView.setNeedsDisplay()
//        }
    }


}

