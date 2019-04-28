//
//  ViewController.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 10/03/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    @IBOutlet weak var dayNightModeButt: UIButton!
    var dataArr: [ChartGroupData] = []
    var selectedData: Int = 0
    var cellBg: UIColor = .white
    var mode: Mode = .day
    
    var cells: [IndexPath: ChartCell] = [:]
    
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
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        readChartData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    @IBAction func switchNightDayMode(sender: UIButton) {
        let aper: Apereance
        if mode == .day {
            mode = .night
            aper = .night
            dayNightModeButt.setTitle("Switch to Day Mode", for: .normal)
        } else {
            mode = .day
            aper = .day
            dayNightModeButt.setTitle("Switch to Night Mode", for: .normal)
        }
        dayNightModeButt.backgroundColor = aper.bg
        
        for cell in cells.values {
            cell.backgroundColor = aper.bg
            cell.chart.update(apereance: aper)
            cell.selectChart.update(apereance: aper)
        }
//        UIView.animate(withDuration: 0.2) {
//        self.chartView.mode = newMode
        update(apereance: aper)
//        setMode(mode)
//        }
    }
    
    func update(apereance: Apereance) {
        navigationController?.navigationBar.barStyle = apereance.navBarStyle
        cellBg = apereance.bg
        tableView.backgroundColor = apereance.scrollBg
        tableView.separatorColor = apereance.tableSeparator
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: apereance.textColor]
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
        
        // table view have strange logic with reuse cells
        // if we do not see this cell, it creates anyway on screen appear
        // so all cells are created in one time, then seams some of them frees
        // only after this it start to reuse cells
        
        if let cell = cells[indexPath] {
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as? ChartCell else {
            return UITableViewCell()
        }
        
        cell.chart.minValueFixedZero = indexPath.section >= 2
        cell.display(groupData: dataArr[indexPath.section])
        cells[indexPath] = cell
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

