//
//  OutputImageViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class OutputImageViewModel: ControlViewModel, Resizable {
    
    let label: String?
    
    var isRequired: Bool = true
    
    let id: String
    
    var size: CGSize?
    
    let type: ControlType = .outputImage
    
    let value: URL
    
    let messageDate: Date?
    
    init(id: String, label: String? = nil, value: URL, messageDate: Date) {
        self.label = label
        self.value = value
        self.id = id
        self.messageDate = messageDate
    }
}
