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
    
    fileprivate func applyTheme(_ model: ChatMessageModel, _ control: ControlProtocol) {
        let controlTheme = model.isLiveAgentConversation ? model.theme.controlThemeForAgent() : model.theme.controlThemeForBot()
        control.applyTheme(controlTheme)
        backgroundColor = model.theme.backgroundColor
    }
    
    func configure(with model: ChatMessageModel, resourceProvider: ControlResourceProvider) {
        guard let controlModel = model.controlModel else { return }
        let control = ControlsUtil.controlForViewModel(controlModel, resourceProvider: resourceProvider)
        addUIControl(control, at: .left, lastMessageDate: model.lastMessageDate)
        
        applyTheme(model, control)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        control?.viewController.view.removeFromSuperview()
    }
    
    // MARK: ControlPresentable
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation, lastMessageDate: Date?) {
        guard let controlView = control.viewController.view else { return }
        controlView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(controlView)
        NSLayoutConstraint.activate([controlView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                                     controlView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                                     controlView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)])
        self.control = control
    }
}
