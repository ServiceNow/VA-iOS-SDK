//
//  PickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController, ThemeableControl {
    
    private let headerViewIdentifier = "HeaderView"
    private let footerViewIdentifier = "FooterView"
    private let fullSizeContainer = FullSizeScrollViewContainerView()
    private var theme: ControlTheme?
    
    weak var delegate: PickerViewControllerDelegate?
    
    var visibleItemCount: Int = 3 {
        didSet {
            fullSizeContainer.maxVisibleItemCount = visibleItemCount

            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
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
        view.setContentHuggingPriority(.required, for: .vertical)
    }
    
    private func setupPickerView() {
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.sectionFooterHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.estimatedSectionFooterHeight = model.isMultiSelect ? 50 : 0
        tableView.tableFooterView = UIView()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        
        if model.isMultiSelect {
            tableView.register(SelectableViewCell.self, forCellReuseIdentifier: SelectableViewCell.cellIdentifier)
        } else {
            let bundle = Bundle(for: PickerViewController.self)
            tableView.register(UINib(nibName: "PickerTableViewCell", bundle: bundle), forCellReuseIdentifier: PickerTableViewCell.cellIdentifier)
        }
        
        tableView.register(PickerHeaderView.self, forHeaderFooterViewReuseIdentifier: headerViewIdentifier)
        tableView.register(PickerFooterView.self, forHeaderFooterViewReuseIdentifier: footerViewIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.bounces = false
        
        // There's an ugly UI glitch due to that option..
        // Picker UIControl is changing its content inset if it is displayed on the very bottom in iPhone X
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        tableView.isScrollEnabled = false
        fullSizeContainer.maxVisibleItemCount = visibleItemCount
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
        guard let configurableCell = cell as? ConfigurablePickerCell else {
            return cell
        }
        configurableCell.applyTheme(theme)
        let itemModel = model.items[indexPath.row]
        configurableCell.configure(withModel: itemModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.selectItem(at: indexPath.row)
        
        // Without adding `performWithoutAnimation` we will get ugly glitch when selecting items at the bottom of the table view
        // That is caused by estimatedRowHeight not being accurate.
        // Under the hood table view set contentOffset based on estimatedHeight of the row, and then adjusts it to an actual value.
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        // for non-multiselect control we are just done here. Otherwise we just send didSelectItem: callback
        if !model.isMultiSelect {
            delegate?.pickerViewController(self, didFinishWithModel: model)
        } else {
            let selectedItemModel = model.items[indexPath.row]
            delegate?.pickerViewController(self, didSelectItem: selectedItemModel, forPickerModel: model)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerViewIdentifier) as! PickerHeaderView
        headerView.titleLabel?.text = model.label
        headerView.contentView.backgroundColor = theme?.headerBackgroundColor
        headerView.titleLabel?.textColor = theme?.headerFontColor
        headerView.titleLabel?.backgroundColor = theme?.headerBackgroundColor
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard model.isMultiSelect else { return nil }
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerViewIdentifier) as! PickerFooterView
        footerView.doneButton?.addTarget(self, action: #selector(doneButtonSelected(_:)), for: .touchUpInside)
        footerView.contentView.backgroundColor = theme?.headerBackgroundColor
        footerView.doneButton?.backgroundColor = theme?.headerBackgroundColor
        footerView.doneButton?.setTitleColor(theme?.headerBackgroundColor, for: .normal)
        return footerView
    }
    
    @objc func doneButtonSelected(_ sender: UIButton) {
        guard model.selectedItems.count != 0 else {
            Logger.default.logDebug("Didn't select any item!")
            return
        }
        
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
    
    // MARK: - Theme
    
    func applyTheme(_ theme: ControlTheme?) {
        self.theme = theme
        tableView.backgroundColor = theme?.backgroundColor
        let headerView = tableView.headerView(forSection: 0) as? PickerHeaderView
        headerView?.backgroundColor = theme?.headerBackgroundColor
        headerView?.titleLabel?.textColor = theme?.headerFontColor
        headerView?.titleLabel?.backgroundColor = theme?.headerBackgroundColor
        
        let footerView = tableView.footerView(forSection: 0) as? PickerFooterView
        footerView?.backgroundColor = theme?.headerBackgroundColor
        footerView?.doneButton?.backgroundColor = theme?.headerBackgroundColor
        footerView?.doneButton?.setTitleColor(theme?.headerBackgroundColor, for: .normal)
    }
}
