//
//  DateTimePickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class DateTimePickerViewController: UIViewController {
    
    private enum DisplayMode {
        case time
        case date
        case dateTime
    }
    
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private(set) weak var doneButton: UIButton!
    @IBOutlet private weak var selectedDateLabel: UILabel!
    @IBOutlet private weak var dateTitleLabel: UILabel!
    
    var model: DateTimePickerControlViewModel? {
        didSet {
            guard let model = model, isViewLoaded == true else { return }
            switch model.type {
            case .dateTime:
                displayMode = .dateTime
            case .time:
                displayMode = .time
            case .date:
                displayMode = .date
            default:
                fatalError("Wrong model assigned")
            }
            
            updateSelectedDateLabelWithDate(datePicker.date)
        }
    }
    
    private var displayMode: DisplayMode = .dateTime {
        didSet {
            updateDateTitleLabel()
            updatePickerMode()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.backgroundColor = UIColor.white
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        updateSelectedDateLabelWithDate(datePicker.date)
        updateDateTitleLabel()
        updatePickerMode()
    }
    
    private func updateDateTitleLabel() {
        let title: String
        switch displayMode {
        case .dateTime:
            title = NSLocalizedString("Select date and time", comment: "Title label for dateTime picker")
        case .time:
            title = NSLocalizedString("Select time", comment: "Title label for time picker")
        case .date:
            title = NSLocalizedString("Select date", comment: "Title label for date picker")
        }
        
        dateTitleLabel.text = title
    }
    
    private func updatePickerMode() {
        let mode: UIDatePickerMode
        switch displayMode {
        case .dateTime:
            mode = .dateAndTime
        case .time:
            mode = .time
        case .date:
            mode = .date
        }
        
        datePicker.datePickerMode = mode
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        updateSelectedDateLabelWithDate(sender.date)
    }
    
    private func updateSelectedDateLabelWithDate(_ date: Date) {
        let dateFormatter = DateFormatter.dateTimeFormatter
        let dateString = dateFormatter.string(from: date)
        selectedDateLabel.text = dateString
        model?.value = adjustedDateToPickerMode(date)
    }
    
    private func adjustedDateToPickerMode(_ date: Date) -> Date {
        let calendar: Calendar = datePicker.calendar
        switch displayMode {
        case .date:
            guard let adjustedDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) else {
                fatalError("Error during date adjustment")
            }
            
            return adjustedDate
        case .dateTime:
            return date
        case .time:
            var adjustedComponents = DateComponents()
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
            adjustedComponents.setValue(timeComponents.hour, for: .hour)
            adjustedComponents.setValue(timeComponents.minute, for: .minute)
            adjustedComponents.setValue(timeComponents.second, for: .second)
            
            adjustedComponents.setValue(1, for: .day)
            adjustedComponents.setValue(1, for: .month)
            adjustedComponents.setValue(1970, for: .year)
            guard let adjustedDate = calendar.date(from: adjustedComponents) else {
                fatalError("Error during date adjustment")
            }
            
            return adjustedDate
        }
    }
}
