//
//  OutputHtmlControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputHtmlControlViewModel: ControlViewModel {
    
    let label: String?
    
    let isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .outputHtml
    
    let value: String
    
    init(id: String, label: String? = nil, value: String) {
        self.label = label
        self.value = value
        self.id = id
    }
}
