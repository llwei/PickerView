//
//  PickerView.swift
//  PickerView
//
//  Created by lailingwei on 16/4/28.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

typealias PickerAllCancelHandler = (() -> Void)
typealias PickerTypeDataSourceDoneHandler = ((_ selectedRows: [Int], _ results: [String]) -> Void)
typealias PickerTypeDateDoneHandler = ((_ selectedDate: Date, _ dateString: String?) -> Void)
typealias PickerTypeAreaDoneHandler = ((_ province: String?, _ city: String?, _ district: String?) -> Void)

typealias PickerColors = (toolbarColor: UIColor, itemColor: UIColor, pickerColor: UIColor)
typealias PickerItemTitles = (cancelTitle: String?, centerTitle: String?, doneTitle: String?)


/**
 当前控件类型
 
 - DataSource:  数据源类型Picker
 - Date:        系统日期Picker
 - Area:        国内地区Picker
 */
@objc enum PickerType: Int {
    case dataSource     = 1
    case date           = 2
    case area           = 3
}


/**
 地区选择器类型
 
 - ProvinceCityDistrict: 省市区三级
 - ProvinceCity:         省市二级
 */
@objc enum AreaType: Int {
    case provinceCityDistrict   = 1
    case provinceCity           = 2
}


class PickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate {
    
    fileprivate struct DefaultValue {
        static let pickerHeight: CGFloat = 216
        static let toolBarHeight: CGFloat = 44
        static let dismissDuration: TimeInterval = 0.3
        static let showDuration: TimeInterval = 0.4
        static var itemTitles: PickerItemTitles = (" 取消", nil, "确定 ")
        static var pickerColors: PickerColors = (UIColor.groupTableViewBackground,
                                          UIColor.darkGray,
                                          UIColor.white)
    }
    
    // MARK: - Properties
    
    fileprivate var pickerType = PickerType.dataSource
    fileprivate var contentView = UIView()
    fileprivate var pickerView: UIView!
    fileprivate var cancelHandler: PickerAllCancelHandler?
    
    fileprivate var contentBottomConstraint: NSLayoutConstraint!
    fileprivate var windowHoriConstraints: [NSLayoutConstraint]?
    fileprivate var windowVertConstraints: [NSLayoutConstraint]?
    
    
    /* ********************************************
     @Type: PickerType.DataSource
     ******************************************** */
    
    fileprivate lazy var dataSourceAry: [[String]] = {
        return [[String]]()
    }()
    fileprivate var selectedRowAry: [Int] = {
        return [Int]()
    }()
    fileprivate var selectedResultAry: [String] = {
        return [String]()
    }()
    fileprivate var maxValueInRowsAry: [Int]?
    fileprivate var dataSourceTypeDoneHandler: PickerTypeDataSourceDoneHandler?
    
    
    /* ********************************************
     @Type: PickerType.DateMode
     ******************************************** */
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        return DateFormatter()
    }()
    fileprivate var datePickerMode: UIDatePicker.Mode = .date
    fileprivate var dateModeTypeDoneHandler: PickerTypeDateDoneHandler?
    
    
    /* ********************************************
     @Type: PickerType.AreaMode
     ******************************************** */
    
    fileprivate var areaType: AreaType = .provinceCityDistrict
    fileprivate lazy var areaSource: [[String : Any]] = {
        return [[String : Any]]()
    }()
    fileprivate var cities = [[String : Any]]()
    fileprivate var districts = [String]()
    fileprivate var province: String?
    fileprivate var city: String?
    fileprivate var district: String?
    fileprivate var areaTypeDoneHandler: PickerTypeAreaDoneHandler?
    
    
    
    // MARK: - Life cycle
    
    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(NSStringFromClass(PickerView.self)).deinit")
    }
    
    // 配置底层遮罩视图
    fileprivate func setupMaskView() {
        
        isUserInteractionEnabled = true
        
        // Add tap gesture to dismiss Self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(PickerView.dismiss))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // 配置内容部分底视图
    fileprivate func setupContentView() {
        
        contentView.backgroundColor = UIColor.white
        let toolBar = setupToolBar()
        pickerView = setupPickerView()
        
        addSubview(contentView)
        contentView.addSubview(toolBar)
        contentView.addSubview(pickerView)
        
        // add constraints
        contentViewAddConstraints()
        addConstraintsWithToolBar(toolBar: toolBar, pickerView: pickerView)
        
    }
    
    // 配置工具条
    fileprivate func setupToolBar() -> UIToolbar {
        
        // space Item
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil,
                                        action: nil)
        
        // Cancel Item
        let cancelTitle = DefaultValue.itemTitles.cancelTitle
        let leftItem = UIBarButtonItem(title: cancelTitle,
                                       style: .done,
                                       target: self,
                                       action: (cancelTitle?.isEmpty == false) ? #selector(PickerView.dismiss) : nil)
        leftItem.tintColor = DefaultValue.pickerColors.itemColor
        
        // Title Item
        let centerLabel = UILabel()
        centerLabel.text = DefaultValue.itemTitles.centerTitle
        centerLabel.textColor = DefaultValue.pickerColors.itemColor
        let titleItem = UIBarButtonItem(customView: centerLabel)
        
        
        // Done Item
        let rightItem = UIBarButtonItem(title: DefaultValue.itemTitles.doneTitle,
                                        style: .done,
                                        target: self,
                                        action: #selector(PickerView.done))
        rightItem.tintColor = DefaultValue.pickerColors.itemColor
        
        
        // ToolBar
        let toolBar = UIToolbar(frame: CGRect.zero)
        toolBar.barTintColor = DefaultValue.pickerColors.toolbarColor
        toolBar.items = [leftItem, spaceItem, titleItem, spaceItem, rightItem]
        
        return toolBar
    }
    
    // 配置PickerView
    fileprivate func setupPickerView() -> UIView {
        
        var picker: UIView!
        
        switch pickerType {
        case .date:
            picker = UIDatePicker(frame: CGRect.zero)
            (picker as! UIDatePicker).datePickerMode = datePickerMode
            
        default:
            picker = UIPickerView(frame: CGRect.zero)
            (picker as! UIPickerView).dataSource = self
            (picker as! UIPickerView).delegate = self
            break
        }
        picker.backgroundColor = DefaultValue.pickerColors.pickerColor
        
        return picker
    }
    
    
    // MARK: - Target actions
    
    @objc func dismiss() {
        
        dismissSelf()
        cancelHandler?()
    }
    
    @objc func done() {
        
        dismissSelf()
        
        switch pickerType {
        case .dataSource:
            guard dataSourceAry.count > 0 else {
                print("当前Picker数据源数量为0")
                return
            }
            dataSourceTypeDoneHandler?(selectedRowAry, selectedResultAry)
            
        case .area:
            areaTypeDoneHandler?(province, city, district)
            
        case .date:
            if let datePicker = pickerView as? UIDatePicker {
                dateModeTypeDoneHandler?(datePicker.date, dateFormatter.string(from: datePicker.date))
            }
        }
        
    }
    
    // MARK: - Helper methods
    
    fileprivate func dismissSelf() {
        
        UIView.animate(withDuration: DefaultValue.dismissDuration, animations: {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            self.contentBottomConstraint.constant = DefaultValue.pickerHeight + DefaultValue.toolBarHeight
            self.layoutIfNeeded()
            
        }) { (flag:Bool) in
            if flag {
                self.windowRemoveConstraints()
                self.removeFromSuperview()
            }
        }
    }
    
    
    // MARK: - Helper for constraints
    
    fileprivate func contentViewAddConstraints() {
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|",
                                                             options: .directionLeadingToTrailing,
                                                             metrics: nil,
                                                             views: ["contentView" : contentView])
        contentBottomConstraint = NSLayoutConstraint(item: contentView,
                                                     attribute: .bottom,
                                                     relatedBy: .equal,
                                                     toItem: self,
                                                     attribute: .bottom,
                                                     multiplier: 1.0,
                                                     constant: 0.0)
        let heightConstraint = NSLayoutConstraint(item: contentView,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: DefaultValue.pickerHeight + DefaultValue.toolBarHeight)
        
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activate(horiConstraints)
            NSLayoutConstraint.activate([contentBottomConstraint, heightConstraint])
        } else {
            addConstraints(horiConstraints)
            addConstraint(contentBottomConstraint)
            addConstraint(heightConstraint)
        }
    }
    
    fileprivate func windowAddConstraints() {
        
        translatesAutoresizingMaskIntoConstraints = false
        windowHoriConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[self]|",
                                                               options: .directionLeadingToTrailing,
                                                               metrics: nil,
                                                               views: ["self" : self])
        windowVertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[self]|",
                                                               options: .directionLeadingToTrailing,
                                                               metrics: nil,
                                                               views: ["self" : self])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activate(windowHoriConstraints!)
            NSLayoutConstraint.activate(windowVertConstraints!)
        } else {
            addConstraints(windowHoriConstraints!)
            addConstraints(windowVertConstraints!)
        }
    }
    
    fileprivate func windowRemoveConstraints() {
        
        if let horiConstraints = windowHoriConstraints {
            removeConstraints(horiConstraints)
        }
        if let vertConstraints = windowVertConstraints {
            removeConstraints(vertConstraints)
        }
    }
    
    private func addConstraintsWithToolBar(toolBar: UIToolbar, pickerView: UIView) {
        // ToolBar
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        let horiForToolBarConstrants = NSLayoutConstraint.constraints(withVisualFormat: "H:|[toolBar]|",
                                                                      options: .directionLeadingToTrailing,
                                                                      metrics: nil,
                                                                      views: ["toolBar" : toolBar])
        let heightForToolBarConstrant = NSLayoutConstraint(item: toolBar,
                                                           attribute: .height,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: DefaultValue.toolBarHeight)
        // PickerView
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        let horiForPickerConstrants = NSLayoutConstraint.constraints(withVisualFormat: "H:|[pickerView]|",
                                                                     options: .directionLeadingToTrailing,
                                                                     metrics: nil,
                                                                     views: ["pickerView" : pickerView])
        let heightForPickerConstrant = NSLayoutConstraint(item: pickerView,
                                                          attribute: .height,
                                                          relatedBy: .equal,
                                                          toItem: nil,
                                                          attribute: .notAnAttribute,
                                                          multiplier: 1.0,
                                                          constant: DefaultValue.pickerHeight)
        
        // Vert
        let vertConstrants = NSLayoutConstraint.constraints(withVisualFormat: "V:|[toolBar][pickerView]|",
                                                            options: .directionLeadingToTrailing,
                                                            metrics: nil,
                                                            views: ["toolBar" : toolBar, "pickerView" : pickerView])
        
        contentView.addConstraints(horiForToolBarConstrants)
        contentView.addConstraint(heightForToolBarConstrant)
        contentView.addConstraints(horiForPickerConstrants)
        contentView.addConstraint(heightForPickerConstrant)
        contentView.addConstraints(vertConstrants)
    }
    
    private func handleMaxValueInRowsWithCurrentRow(row: Int, compont: Int) {
        guard let maxValueInRowsAry = self.maxValueInRowsAry else {
            return;
        }
        for index in 0..<dataSourceAry.count {
            let selectedRow = selectedRowAry[index]
            let maxRow = maxValueInRowsAry[index]
            if selectedRow < maxRow {
                return
            }
            
            (pickerView as! UIPickerView).selectRow(maxRow, inComponent: index, animated: true)
            selectedRowAry[index] = maxRow
            selectedResultAry[index] = dataSourceAry[index][maxRow]
        }
    }
    
    
    // MARK: - UIPicker dataSource / delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        switch pickerType {
        case .dataSource:
            return dataSourceAry.count
            
        case .area:
            return areaType == .provinceCityDistrict ? 3 : 2;
            
        case .date:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch pickerType {
        case .dataSource:
            return dataSourceAry[component].count
            
        case .area:
            switch areaType {
            case .provinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    return areaSource.count
                case 1:
                    // 市
                    return cities.count
                case 2:
                    // 区
                    return districts.count
                default:
                    return 0
                }
                
            case .provinceCity:
                switch component {
                case 0:
                    // 省
                    return areaSource.count
                case 1:
                    // 市
                    return cities.count
                default:
                    return 0
                }
            }
            
        case .date:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerType {
        case .dataSource:
            return dataSourceAry[component][row]
            
        case .area:
            switch areaType {
            case .provinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    return areaSource[row]["state"] as? String
                case 1:
                    // 市
                    return cities[row]["city"] as? String
                case 2:
                    // 区
                    return districts[row]
                default:
                    return nil
                }
                
            case .provinceCity:
                switch component {
                case 0:
                    // 省
                    return areaSource[row]["state"] as? String
                case 1:
                    // 市
                    return cities[row]["city"] as? String
                default:
                    return nil
                }
            }
            
        case .date:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerType {
        case .dataSource:
            selectedRowAry[component] = row
            selectedResultAry[component] = dataSourceAry[component][row]
            if let _ = self.maxValueInRowsAry {
                // 处理每列最大值
                handleMaxValueInRowsWithCurrentRow(row: row, compont: component)
            }
            
        case .area:
            switch areaType {
            case .provinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    guard areaSource.count > 0 else {
                        return
                    }
                    province = areaSource[row]["state"] as? String
                    if let theCities = areaSource[row]["cities"] as? [[String : Any]] {
                        cities = theCities
                        city = cities.first?["city"] as? String
                        
                        if let theDistricts = cities.first?["areas"] as? [String] {
                            districts = theDistricts
                            district = theDistricts.first
                        } else {
                            district = nil
                        }
                    } else {
                        city = nil
                        district = nil
                    }
                    pickerView.selectRow(0, inComponent: 1, animated: true)
                    pickerView.reloadComponent(1)
                    pickerView.selectRow(0, inComponent: 2, animated: true)
                    pickerView.reloadComponent(2)
                    
                case 1:
                    // 市
                    guard cities.count > 0 else {
                        return
                    }
                    city = cities[row]["city"] as? String
                    if let theDistricts = cities[row]["areas"] as? [String] {
                        districts = theDistricts
                        district = theDistricts.first
                    } else {
                        district = nil
                    }
                    pickerView.selectRow(0, inComponent: 2, animated: true)
                    pickerView.reloadComponent(2)
                    
                case 2:
                    // 区
                    guard districts.count > 0 else {
                        return
                    }
                    district = districts[row]
                    
                default:
                    break
                }
                
            case .provinceCity:
                switch component {
                case 0:
                    // 省
                    guard areaSource.count > 0 else {
                        return
                    }
                    province = areaSource[row]["state"] as? String
                    if let theCities = areaSource[row]["cities"] as? [[String : Any]] {
                        cities = theCities
                        city = cities.first?["city"] as? String
                    } else {
                        city = nil
                    }
                    pickerView.selectRow(0, inComponent: 1, animated: true)
                    pickerView.reloadComponent(1)
                    
                case 1:
                    // 市
                    guard cities.count > 0 else {
                        return
                    }
                    city = cities[row]["city"] as? String
                    
                default:
                    break
                }
            }
            
        case .date:
            break
        }
    }
    
    
    // MARK: - UIGesture delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 确保点击dismiss时，手势区域在有效区域
        guard let touchView = touch.view else {
            return false
        }
        
        return touchView.isKind(of: PickerView.self)
    }
    
    
    // MARK: - ================== Public methods ==================
    
    /**
     显示PickerView
     */
    func show() {
        guard let window = UIApplication.shared.keyWindow else {
            print("当前window为空")
            return
        }
        
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        window.addSubview(self)
        windowAddConstraints()
        contentBottomConstraint.constant = DefaultValue.pickerHeight + DefaultValue.toolBarHeight
        layoutIfNeeded()
        
        UIView.animate(withDuration: DefaultValue.showDuration,
                       delay: 0.1,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.0,
                       options: .curveEaseOut,
                       animations: {
                        
                        self.contentBottomConstraint.constant = 0
                        self.layoutIfNeeded()
                        
        }, completion: nil)
    }
    
    
    /**
     取消回调
     */
    func didClickCancelHandler(handler: PickerAllCancelHandler?) {
        cancelHandler = handler
    }
    
}

// MARK: - DataSource

extension PickerView {
    
    /**
     初始化一个数据源类型的Picker
     
     - parameter dataSource: 数据源
     - parameter itemTitles: 标题
     - parameter pickerColors: 颜色
     */
    convenience init(aDataSources: [[String]], itemTitles: PickerItemTitles? = nil, pickerColors: PickerColors? = nil) {
        self.init(frame: CGRect.zero)
        
        if aDataSources.count == 0 {
            print("\(NSStringFromClass(PickerView.self))数据源数量不应为空")
        }
        if let titles = itemTitles {
            DefaultValue.itemTitles = titles
        }
        if let colors = pickerColors {
            DefaultValue.pickerColors = colors
        }
        
        pickerType = .dataSource
        dataSourceAry = aDataSources
        selectedRowAry = Array(repeatElement(0, count: aDataSources.count))
        selectedResultAry = [String]()
        for index in 0..<aDataSources.count {
            guard let result = aDataSources[index].first else {
                assertionFailure("picker中第\(index)组数据为空数据")
                return
            }
            selectedResultAry.append(result)
        }

        setupMaskView()
        setupContentView()
    }
    
    /**
     滚动到对应的行
     
     - parameter aRows:     对应的行数组
     - parameter animated:  是否动画滚动
     */
    func showSelectedRows(aRows: [Int], animated: Bool) {
        guard pickerType == .dataSource else {
            print("当前PickerType不为DataSource")
            return
        }
        guard aRows.count == dataSourceAry.count else {
            print("目标row的数量与dataSourceAry数量不一致")
            return
        }
        
        // 更新选择的行和值
        for index in 0..<aRows.count {
            let selectedRow: Int = aRows[index]
            guard selectedRow >= 0 else {
                print("目标行为负数");
                return
            }
            let selectedResult: String = dataSourceAry[index][selectedRow]
            
            (pickerView as! UIPickerView).selectRow(selectedRow, inComponent: index, animated: animated)
            selectedRowAry[index] = selectedRow
            selectedResultAry[index] = selectedResult
        }
    }
    
    
    /**
     dataSource类型Picker点击确定回调
     */
    func didClickDoneForTypeDataSourceHandler(handler: PickerTypeDataSourceDoneHandler?) {
        
        guard pickerType == .dataSource else {
            print("当前PickerType不为dataSource")
            return
        }
        dataSourceTypeDoneHandler = handler
    }
    
    /**
     设置最大值时，对应各个row的值
     */
    func setMaxValuesInRows(maxValueInRowAry: [Int]) {
        guard pickerType == .dataSource else {
            print("当前PickerType不为DataSource")
            return;
        }
        guard maxValueInRowAry.count == dataSourceAry.count else {
            print("设置最大值的列数，与数据源列数不一致")
            return;
        }
        
        self.maxValueInRowsAry = maxValueInRowAry
    }
}


// MARK: - Date

extension PickerView {
    
    /**
     初始化一个日期Picker
     
     - parameter aDatePickerMode:   日期类型
     - parameter itemTitles: 标题
     - parameter pickerColors: 颜色
     */
    convenience init(aDatePickerMode: UIDatePicker.Mode, itemTitles: PickerItemTitles? = nil, pickerColors: PickerColors? = nil) {
        self.init(frame: CGRect.zero)
        
        if let titles = itemTitles {
            DefaultValue.itemTitles = titles
        }
        if let colors = pickerColors {
            DefaultValue.pickerColors = colors
        }
        
        pickerType = .date
        datePickerMode = aDatePickerMode
        
        setupMaskView()
        setupContentView()
    }
    
    /**
     设置当前时间
     */
    func setDate(date: Date, animated: Bool) {
        
        guard pickerType == .date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            picker.setDate(date, animated: animated)
        }
    }
    
    
    func didClickDoneForTypeDateWithFormat(dateFormat: String?, handler: PickerTypeDateDoneHandler?) {
        
        guard pickerType == .date else {
            print("当前PickerType不为Date")
            return
        }
        
        dateFormatter.dateFormat = dateFormat
        dateModeTypeDoneHandler = handler
    }
    
    
    /**
     设置datePicker的最大最小时间  When min > max, the values are ignored. Ignored in countdown timer mode
     
     - parameter minimumDate: 最小时间
     - parameter maximumDate: 最大时间
     */
    func setMinimumDate(minimumDate: Date?, maximumDate: Date?) {
        
        guard pickerType == .date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            guard datePickerMode != .dateAndTime else {
                return
            }
            picker.minimumDate = minimumDate
            picker.maximumDate = maximumDate
        }
    }
    
    
    /**
     设置倒计时
     
     - parameter countDownDuration: for UIDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59
     - parameter minuteInterval:    interval must be evenly divided into 60. default is 1. min is 1, max is 30
     */
    func setCountDownDuration(countDownDuration: TimeInterval, minuteInterval: Int) {
        
        guard pickerType == .date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            guard datePickerMode == .dateAndTime else {
                return
            }
            picker.countDownDuration = countDownDuration
            picker.minuteInterval = minuteInterval
        }
    }
    
}

// MARK: - Area

extension PickerView {
    
    /**
     初始化一个地区选择器
     
     - parameter anAreaType: 地区选择器目录类型
     - parameter itemTitles: 标题
     - parameter pickerColors: 颜色
     */
    convenience init(anAreaType: AreaType, itemTitles: PickerItemTitles? = nil, pickerColors: PickerColors? = nil) {
        self.init(frame: CGRect.zero)
        
        if let titles = itemTitles {
            DefaultValue.itemTitles = titles
        }
        if let colors = pickerColors {
            DefaultValue.pickerColors = colors
        }
        
        pickerType = .area
        areaType = anAreaType
        
        // 获取数据
        let fileName = areaType == .provinceCityDistrict ? "area1" : "area2"
        print(fileName)
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "plist") {
            
            areaSource = NSArray(contentsOfFile: filePath) as! [[String : Any]]
            if let theState = areaSource.first {
                
                province = theState["state"] as? String
                if let theCities = theState["cities"] as? [[String : Any]] {
                    
                    cities = theCities
                    if let theCity = theCities.first {
                        
                        city = theCity["city"] as? String
                        if areaType == .provinceCityDistrict {
                            if let theDistricts = theCity["areas"] as? [String] {
                                
                                districts = theDistricts
                                district = theDistricts.first
                            }
                        }
                    }
                }
            }
        } else {
            fatalError("没找到地区数据\(fileName)源文件")
        }
        
        setupMaskView()
        setupContentView()
    }
    
    
    /**
     Area类型Picker点击确定回调击
     */
    func didClickDoneForTypeAreaHandler(handler: PickerTypeAreaDoneHandler?) {
        
        guard pickerType == .area else {
            print("当前PickerType不为Area")
            return
        }
        areaTypeDoneHandler = handler
    }
}


















