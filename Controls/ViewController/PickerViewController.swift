//
//  PickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController {
    
    weak var delegate: PickerViewControllerDelegate?
    
    let headerTextColor = UIColor.controlHeaderTextColor
    
    let fullSizeContainer = FullSizeScrollViewContainerView()
    
    let tableView = UITableView()
    
    var model: PickerControlViewModel {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Initialization
    
    init(model: PickerControlViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func loadView() {
        self.view = fullSizeContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickerView()
    }
    
    private func setupPickerView() {
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.sectionFooterHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.estimatedSectionFooterHeight = model.isMultiSelect ? 50 : 0
        tableView.tableFooterView = model.isMultiSelect ? nil : UIView()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        
        if model.isMultiSelect {
            tableView.register(SelectableViewCell.self, forCellReuseIdentifier: SelectableViewCell.cellIdentifier)
        } else {
            let bundle = Bundle(for: PickerViewController.self)
            tableView.register(UINib(nibName: "PickerTableViewCell", bundle: bundle), forCellReuseIdentifier: PickerTableViewCell.cellIdentifier)
        }
        
        // FIXME: upcoming lots of changes here
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        // TODO: need to adjust based on the number of items, display style etc
        tableView.isScrollEnabled = false
        
        fullSizeContainer.scrollView = tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     tableView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])
        
        tableView.reloadData()
    }
}

// MARK: - PickerViewController + UITableView

extension PickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = model.isMultiSelect ? SelectableViewCell.cellIdentifier : PickerTableViewCell.cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.contentView.backgroundColor = UIColor.white
        cell.selectionStyle = .none
        
        guard let configurableCell: ConfigurablePickerCell = cell as? ConfigurablePickerCell else {
            return cell
        }
        
        let itemModel = model.items[indexPath.row]
        configurableCell.configure(withModel: itemModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItemModel = model.items[indexPath.row]
        selectedItemModel.isSelected = !selectedItemModel.isSelected
        tableView.reloadRows(at: [indexPath], with: .none)
        
        // for non-multiselect control we are just done here. Otherwise we just send didSelectItem: callback
        if !model.isMultiSelect {
            delegate?.pickerViewController(self, didFinishWithModel: model)
        } else {
            delegate?.pickerViewController(self, didSelectItem: selectedItemModel, forPickerModel: model)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = model.label
        titleLabel.textColor = headerTextColor
        headerView.backgroundColor = UIColor.controlHeaderBackgroundColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([titleLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 10),
                                     titleLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -10),
                                     titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 0.8),
                                     titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0)])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        guard model.isMultiSelect else {
            return footerView
        }
        
        let doneButton = UIButton(type: .custom)
        doneButton.addTarget(self, action: #selector(doneButtonSelected(_:)), for: .touchUpInside)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(headerTextColor, for: .normal)
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.backgroundColor = UIColor.controlHeaderBackgroundColor
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(doneButton)
        NSLayoutConstraint.activate([doneButton.leftAnchor.constraint(equalTo: footerView.leftAnchor),
                                     doneButton.rightAnchor.constraint(equalTo: footerView.rightAnchor),
                                     doneButton.topAnchor.constraint(equalTo: footerView.topAnchor),
                                     doneButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor)])
        return footerView
    }
    
    @objc func doneButtonSelected(_ sender: UIButton) {
        guard model.selectedItems.count != 0 else {
            Logger.default.logDebug("Didn't select any item!")
            return
        }
        
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
}
