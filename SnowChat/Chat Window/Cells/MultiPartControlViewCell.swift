//
//  ConversationMultiPartViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class MultiPartControlViewCell: UITableViewCell, ControlPresentable {
    
    static let cellIdentifier = "MultiPartControlViewCell"
    
    private(set) var control: ControlProtocol?
    
    func configure(with model: MultiPartControlViewModel) {
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
                                     controlView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
        self.control = control
        layoutIfNeeded()
    }
}
