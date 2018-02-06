//
//  MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class ButtonControlViewModel: ControlViewModel, ValueRepresentable {
    
    var label: String?
    
    let isRequired = true
    
    let id: String
    
    let type: ControlType = .button
    
    var value: Int
    
    var resultValue: Int? {
        return value
    }
    
    var displayValue: String? {
        return nil
    }
    
    init(id: String, label: String? = nil, value: Int) {
        self.id = id
        self.label = label
        self.value = value
    }
}

class ButtonControl: ControlProtocol {
    
    var model: ControlViewModel
    
    private var multiPartModel: ButtonControlViewModel {
        return model as! ButtonControlViewModel
    }
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let multiPartModel = model as? ButtonControlViewModel else {
            fatalError("Tried to assign wrong model type")
        }
        
        self.model = multiPartModel
        self.viewController = UIViewController()
        setupMoreButton()
    }
    
    private func setupMoreButton() {
        let moreButton = UIButton(type: .custom)
        moreButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        moreButton.layer.cornerRadius = 4
        moreButton.layer.borderColor = UIColor.agentBubbleBackgroundColor.cgColor
        moreButton.layer.borderWidth = 1
        moreButton.setTitle(multiPartModel.label, for: .normal)
        moreButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        moreButton.setTitleColor(.controlHeaderTextColor, for: .normal)
        moreButton.titleLabel?.adjustsFontSizeToFitWidth = true
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.addTarget(self, action: #selector(moreButtonPressed(_:)), for: .touchUpInside)
        
        viewController.view.addSubview(moreButton)
        NSLayoutConstraint.activate([moreButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                                     moreButton.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                                     moreButton.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)])
    }
    
    @objc func moreButtonPressed(_ sender: UIButton) {
        delegate?.control(self, didFinishWithModel: multiPartModel)
    }
}
