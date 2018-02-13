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
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var selectedDateLabel: UILabel!
    
    // TODO: this needs to be centralized
    private var dateFormatter = DateFormatter()
    
    var model: DateTimePickerControlViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        datePicker.backgroundColor = UIColor.white
        datePicker.addTarget(self, action: #selector(dateChanged(_ :)), for: .valueChanged)
        updateSelectedDateLabelWithDate(datePicker.date)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        updateSelectedDateLabelWithDate(sender.date)
    }
    
    private func updateSelectedDateLabelWithDate(_ date: Date) {
        let dateString = dateFormatter.string(from: date)
        selectedDateLabel.text = dateString
    }
}
