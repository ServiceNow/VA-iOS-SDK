//
//  PickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController, ControlStateAdaptable {
    
    weak var delegate: PickerViewControllerDelegate?
    
    let headerTextColor = UIColor.controlHeaderTextColor
    
    var fullSizeContainer: FullSizeScrollViewContainerView?
    
    var tableView: UITableView?
    
    var responseView: UIView?
    
    var model: PickerControlViewModel {
        didSet {
            tableView?.reloadData()
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
        let fullSizeContainer = FullSizeScrollViewContainerView(frame: CGRect.zero)
        self.view = fullSizeContainer
        self.fullSizeContainer = fullSizeContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews(forState: .regular)
    }
    
    func updateControlState(_ state: ControlState) {
        
        // we can only transition to submitted state
        guard state == .submitted else {
            return
        }
        
        setupMessageAndResponseView()
    }
    
    private func setupViews(forState state: ControlState) {
        switch state {
        case .regular:
            setupPickerView()
        case .submitted:
            setupMessageAndResponseView()
        }
    }
    
    private func setupMessageAndResponseView() {
        guard let fullSizeContainer = fullSizeContainer else {
            return
        }
        
        // HA! first time using nested functions in Swift..pretty nice!
        func setupTextView(_ textView: UITextView) {
            textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            textView.isScrollEnabled = false
            textView.font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        let messageView = UITextView()
        let responseView = UITextView()
        
        // main message view (question for the user)
        setupTextView(messageView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(messageView)
        NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     messageView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     messageView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     messageView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])
        fullSizeContainer.scrollView = messageView
        fullSizeContainer.maxHeight = 200
        
        // response view
        setupTextView(responseView)
        self.responseView = responseView
    }
    
    private func setupPickerView() {
        guard let fullSizeContainer = fullSizeContainer else {
            return
        }
        
        let tableView = UITableView()
        tableView.estimatedSectionFooterHeight = model.isMultiSelect ? 30 : 0
        
        let bundle = Bundle(for: PickerViewController.self)
        if model.isMultiSelect {
            tableView.register(SelectableViewCell.self, forCellReuseIdentifier: SelectableViewCell.cellIdentifier)
        } else {
            tableView.register(UINib(nibName: "PickerTableViewCell", bundle: bundle), forCellReuseIdentifier: PickerTableViewCell.cellIdentifier)
        }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     tableView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])
        
        // FIXME: upcoming lots of changes here
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        tableView.sectionHeaderHeight = 30
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // TODO: need to adjust based on the number of items, display style etc
        tableView.isScrollEnabled = false
        self.tableView = tableView
        
        fullSizeContainer.scrollView = tableView
        fullSizeContainer.maxHeight = 200
        
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
                                     doneButton.heightAnchor.constraint(equalTo: footerView.heightAnchor),
                                     doneButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: 0)])
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
