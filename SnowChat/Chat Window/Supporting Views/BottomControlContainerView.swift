//
//  BottomControlContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/3/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class BottomControlContainerView: UIView, ControlPresentable {
    
    private(set) var control: ControlProtocol?
    
    var model: ChatMessageModel? {
        didSet {
            guard let messageModel = model else { return }
            let control = ControlsUtil.controlForViewModel(messageModel.controlModel)
            addUIControl(control, at: .left)
        }
    }
    
    // MARK: ControlPresentable
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard let controlView = control.viewController.view else { return }
        controlView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(controlView)
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: topAnchor),
                                     controlView.heightAnchor.constraint(equalToConstant: 50)])
        self.control = control
        layoutIfNeeded()
    }
}
