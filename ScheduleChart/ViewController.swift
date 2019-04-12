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
    @IBOutlet weak var dayNightModeButt: UIButton!
    @IBOutlet weak var selectChartDisplay: SelectChartDisplayedView!
    var dataArr: [ChartGroupData] = []
    var selectedData: Int = 0
    var cellBg: UIColor = .white
    
    func readChartData() {
        for i in 1...5 {
            let path = "contest/\(i)/overview"
            
            if let url = Bundle.main.url(forResource: path, withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = obj as? [String: Any] {
                
                let groupData = ChartGroupData.readDictionary(dic: json)
                if groupData.data.count > 0 {
                    dataArr.append(groupData)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readChartData()
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
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
    }
}

extension ViewController { // table
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataArr.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as? ChartCell else {
            return UITableViewCell()
        }
        
        cell.display(groupData: dataArr[indexPath.section])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = dataArr[indexPath.section]
        return ChartCell.getHeight(withData: d, width: tableView.bounds.width)
    }
    
    func increaseChartSize(groupData: ChartGroupData) -> ChartGroupData {
        var data = groupData.data
        let count = data[0].items.count
        for i in (0..<count).reversed() {
            for ii in 0..<data.count {
                let items = data[ii].items
                let time = items[items.count-1].time - items[items.count-2].time + items[items.count-1].time
                
                data[ii].items.append(ChartData.Item(time: time, value: items[i].value))
            }
        }
        return ChartGroupData(type: groupData.type, data: data, scaled: groupData.scaled)
    }
}

