//
//  OutputLinkControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkControlViewModel: ControlViewModel {
    
    let label: String?
    
    let header: String?
    
    let isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .outputLink
    
    let value: URL

    let messageDate: Date?
    
    init(id: String, label: String? = nil, header: String?, value: URL, messageDate: Date) {
        self.label = label
        self.header = header
        self.value = value
        self.id = id
        self.messageDate = messageDate
    }
}
