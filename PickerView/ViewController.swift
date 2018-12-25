//
//  ViewController.swift
//  PickerView
//
//  Created by Ryan on 2018/12/25.
//  Copyright © 2018 Ryan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // MARK: - AlonePicker
    
    private let alonePicker: PickerView = {
        var dataSource = [String]()
        for i in 0..<20 {
            dataSource.append("\(i)")
        }
        return PickerView(aDataSources: [dataSource])
    }()
    
    @IBAction func showAlonePicker(_ sender: UIButton) {
        alonePicker.show()
        alonePicker.showSelectedRows(aRows: [3], animated: true)
        alonePicker.didClickDoneForTypeDataSourceHandler { (selectedRows: [Int], results: [String]) in
            print("selectedRow:\(selectedRows)")
            print("result:\(results)")
        }
        alonePicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    
    // MARK: - DoublePicker
    
    private let doublePicker: PickerView = {
        var leftSource = [String]()
        for i in 0..<20 {
            leftSource.append("\(i)")
        }
        var rightSource = [String]()
        for i in 0..<20 {
            rightSource.append(".\(i)")
        }
        let picker = PickerView(aDataSources: [leftSource, rightSource])
        // 设置最大值
        picker.setMaxValuesInRows(maxValueInRowAry: [12, 10])
        
        return picker
    }()
    
    @IBAction func showDoublePicker(_ sender: UIButton) {
        doublePicker.show()
        doublePicker.showSelectedRows(aRows: [3, 4], animated: true)
        doublePicker.didClickDoneForTypeDataSourceHandler { (selectedRows: [Int], results: [String]) in
            print("selectedRow:\(selectedRows)")
            print("result:\(results)")
        }
        doublePicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    
    // MARK: - DateModePicker
    
    private let datePicker: PickerView = {
        return PickerView(aDatePickerMode: .date)
    }()
    
    @IBAction func showDatePicker(_ sender: UIButton) {
        
        datePicker.show()
        datePicker.setDate(date: Date(), animated: true)
        datePicker.didClickDoneForTypeDateWithFormat(dateFormat: "yy年MM月dd日 HH:mm:ss") { (selectedDate, dateString) in
            print("selectedDate:\(selectedDate)")
            print("dateString:\(dateString)")
        }
        datePicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    
    
    // MARK: - AreaPicker
    
    private let areaPicker: PickerView = {
        return PickerView(anAreaType: .provinceCityDistrict)
    }()
    
    @IBAction func showAreaPicker(_ sender: UIButton) {
        
        areaPicker.show()
        areaPicker.didClickDoneForTypeAreaHandler { (province, city, district) in
            print("province:\(province)")
            print("city:\(city)")
            print("district:\(district)")
        }
        areaPicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    
}


