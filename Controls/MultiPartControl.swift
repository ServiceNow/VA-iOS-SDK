//
//  MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class MultiPartControlViewModel: ControlViewModel {
    var label: String?
    
    let isRequired = true
    
    let id: String
    
    let type: ControlType = .multiPart
    
    var value: Int
    
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
        let doneButton = UIButton(type: .custom)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        doneButton.setTitle(multiPartModel.label, for: .normal)
        doneButton.setTitleColor(.controlHeaderTextColor, for: .normal)
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(doneButton)
        NSLayoutConstraint.activate([doneButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                                     doneButton.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                                     doneButton.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)])
    }
}
