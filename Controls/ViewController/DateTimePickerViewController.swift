//
//  DateTimePickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class DateTimePickerViewController: UIViewController {
    
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private(set) weak var doneButton: UIButton!
    @IBOutlet private weak var selectedDateLabel: UILabel!
    
    var model: DateTimePickerControlViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.backgroundColor = UIColor.white
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        updateSelectedDateLabelWithDate(datePicker.date)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        updateSelectedDateLabelWithDate(sender.date)
    }
    
    private func updateSelectedDateLabelWithDate(_ date: Date) {
        let dateFormatter = DateFormatter.chatDateFormatter()
        let dateString = dateFormatter.string(from: date)
        selectedDateLabel.text = dateString
        model?.value = date
    }
}
