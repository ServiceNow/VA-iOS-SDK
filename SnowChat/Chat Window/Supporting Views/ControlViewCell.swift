//
//  ControlViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class ControlViewCell: UITableViewCell, ControlPresentable {
    
    static let cellIdentifier = "ControlViewCell"
    
    private(set) var control: ControlProtocol?
    
    func configure(with model: ControlViewModel, resourceProvider: ControlResourceProvider) {
        let control = ControlsUtil.controlForViewModel(model, resourceProvider: resourceProvider)
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
        NSLayoutConstraint.activate([controlView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                                     controlView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                                     controlView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)])
        self.control = control
    }
}
