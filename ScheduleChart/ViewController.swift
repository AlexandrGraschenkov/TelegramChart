//
//  ViewController.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    @IBOutlet weak var chartView: ChartCopmosedView!
    @IBOutlet weak var fpsLabel: DebugFpsLabel!
    @IBOutlet weak var clipSwitch: UISwitch!
    @IBOutlet weak var dayNightModeButt: UIButton!
    @IBOutlet var labels: [UILabel] = []
    @IBOutlet weak var debugFpsSwitch: UISwitch!
    @IBOutlet weak var selectChartDisplay: SelectChartDisplayedView!
    var dataArr: [[ChartData]] = []
    var selectedData: Int = 4
    var cellBg: UIColor = .white
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let url = Bundle.main.url(forResource: "chart_data", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = obj as? [[String: Any]] {
            for i in 0..<5 {
                let data = ChartData.generateData(dic: json[i])
                dataArr.append(data)
            }
        }
        
        selectChartDisplay.displayDelegate = self
        fpsLabel.isEnabled = debugFpsSwitch.isOn
        chartView.data = dataArr[selectedData]
        selectChartDisplay.items = ChartDataInfo.mapInfoFrom(data: chartView.data)
        chartView.displayChart.onDrawDebug = fpsLabel.drawCalled
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

    @IBAction func switchChanged(control: UISwitch) {
        chartView.displayChart.drawOutsideChart = !control.isOn
        chartView.displayChart.setNeedsDisplay()
    }
    
    @IBAction func debugFpsSwitchChanged(sender: UISwitch) {
        fpsLabel.isEnabled = sender.isOn
    }
    
    @IBAction func switchNightDayMode(sender: UIButton) {
        let newMode: ChartCopmosedView.Mode
        if chartView.mode == .day {
            newMode = .night
        } else {
            newMode = .day
        }
        
//        UIView.animate(withDuration: 0.2) {
        self.chartView.mode = newMode
        self.setMode(newMode)
//        }
    }
    
    func setMode(_ mode: ChartCopmosedView.Mode) {
        let bgColor: UIColor
        let separatorColor: UIColor
        let textColor: UIColor
        
        if mode == .night {
            textColor = UIColor.white
            bgColor = UIColor(red:0.10, green:0.13, blue:0.17, alpha:1.00)
            separatorColor = UIColor(red:0.07, green:0.10, blue:0.13, alpha:1.00)
            cellBg = UIColor(red:0.14, green:0.18, blue:0.24, alpha:1.00)
            dayNightModeButt.setTitle("Switch to Day Mode", for: .normal)
            dayNightModeButt.setTitleColor(UIColor(red:0.25, green:0.59, blue:1.00, alpha:1.00), for: .normal)
            navigationController?.navigationBar.barStyle = .black
        } else {
            textColor = UIColor.black
            bgColor = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.00)
            separatorColor = UIColor(red:0.78, green:0.78, blue:0.80, alpha:1.00)
            cellBg = .white
            dayNightModeButt.setTitle("Switch to Night Mode", for: .normal)
            dayNightModeButt.setTitleColor(UIColor(red:0.18, green:0.49, blue:0.96, alpha:1.00), for: .normal)
            navigationController?.navigationBar.barStyle = .default
        }
        
        tableView.separatorColor = separatorColor
        tableView.backgroundColor = bgColor
        tableView.visibleCells.forEach({$0.backgroundColor = self.cellBg})
        selectChartDisplay.backgroundColor = cellBg
        selectChartDisplay.titleColor = textColor
        labels.forEach({$0.textColor = textColor})
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
    }
}

extension ViewController { // table
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath.section == 2 {
            if indexPath.item == selectedData {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        cell.backgroundColor = cellBg
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let prevIdx = IndexPath(row: selectedData, section: 2)
            if prevIdx != indexPath {
                tableView.cellForRow(at: prevIdx)?.accessoryType = .none
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                selectedData = indexPath.row
                chartView.data = dataArr[selectedData]
                selectChartDisplay.items = ChartDataInfo.mapInfoFrom(data: chartView.data)
            }
        }
    }
}

extension ViewController: SelectChartDisplayedViewDelegate {
    func chartDataDisplayChanged(index: Int, display: Bool) {
        chartView.setShowData(index: index, show: display, animated: true)
    }
}

