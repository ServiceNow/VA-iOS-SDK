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
        setupButton()
    }
    
    private func setupButton() {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.layer.cornerRadius = 4
        button.layer.borderColor = UIColor.agentBubbleBackgroundColor.cgColor
        button.layer.borderWidth = 1
        button.setTitle(multiPartModel.label, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.setTitleColor(.controlHeaderTextColor, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(.veryHigh, for: .horizontal)
        viewController.view.addSubview(button)
        NSLayoutConstraint.activate([button.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                                     button.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
                                     button.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                                     button.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        delegate?.control(self, didFinishWithModel: multiPartModel)
    }
}
