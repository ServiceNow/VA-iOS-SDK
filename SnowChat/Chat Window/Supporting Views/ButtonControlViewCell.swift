//
//  ConversationMultiPartViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class ButtonControlViewCell: UITableViewCell, ControlPresentable {
    
    static let cellIdentifier = "ButtonControlViewCell"
    
    private(set) var control: ControlProtocol?
    
    func configure(with model: ButtonControlViewModel) {
        let control = ControlsUtil.controlForViewModel(model)
        addUIControl(control, at: .left)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        control?.viewController.view.removeFromSuperview()
    }
    
    // MARK: ControlPresentable
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard let controlView = control.viewController.view else { return }
        controlView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(controlView)
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
                                     controlView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15)])
        self.control = control
        layoutIfNeeded()
    }
}
