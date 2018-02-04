//
//  BottomControlContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/3/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class BottomControlContainerView: UIView, ControlPresentable {
    
    private(set) var control: ControlProtocol?
    
    func configure(with model: ControlViewModel) {
        let control = ControlsUtil.controlForViewModel(model)
        addUIControl(control, at: .left)
    }
    
    // MARK: ControlPresentable
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard let controlView = control.viewController.view else { return }
        controlView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(controlView)
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        self.control = control
        layoutIfNeeded()
    }
}
