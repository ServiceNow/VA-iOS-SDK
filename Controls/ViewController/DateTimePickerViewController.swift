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
            guard isViewLoaded == true else { return }
            updateDisplayMode()
            updatePickerDate()
            updateSelectedDateLabelWithDate(datePicker.date)
        }
    }
    
    private var displayMode: DisplayMode = .dateTime {
        didSet {
            updateSelectedDateLabelWithDate(datePicker.date)
            updateDateTitleLabel()
            updatePickerMode()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.backgroundColor = UIColor.white
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        updatePickerDate()
        updateSelectedDateLabelWithDate(datePicker.date)
        updateDateTitleLabel()
        updateDisplayMode()
    }
    
    private func updateDisplayMode() {
        guard let model = model else { return }
        
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
        
        updatePickerMode()
    }
    
    private func updatePickerDate() {
        guard let model = model else { return }
        
        switch model.type {
        case .dateTime:
            datePicker.date = Date()
        case .time:
            datePicker.date = Date(timeIntervalSince1970: 0)
        case .date:
            datePicker.date = Date()
        default:
            fatalError("Wrong model assigned")
        }
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
        guard let model = model else { return }
        let dateFormatter = DateFormatter.localDisplayFormatter(for: model.type)
        let dateString = dateFormatter.string(from: date)
        selectedDateLabel.text = dateString
        model.value = date
    }
}
