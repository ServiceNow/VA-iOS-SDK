//
//  MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class MultiPartControlViewModel: ControlViewModel, ValueRepresentable {
    
    var label: String?
    
    let isRequired = true
    
    let id: String
    
    let type: ControlType = .multiPart
    
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

class MultiPartControl: ControlProtocol {
    
    var model: ControlViewModel
    
    private var multiPartModel: MultiPartControlViewModel {
        return model as! MultiPartControlViewModel
    }
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let multiPartModel = model as? MultiPartControlViewModel else {
            fatalError("Tried to assign wrong model type")
        }
        
        self.model = multiPartModel
        self.viewController = UIViewController()
        setupMoreButton()
    }
    
    private func setupMoreButton() {
        let moreButton = UIButton(type: .custom)
        moreButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        moreButton.setTitle(multiPartModel.label, for: .normal)
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
