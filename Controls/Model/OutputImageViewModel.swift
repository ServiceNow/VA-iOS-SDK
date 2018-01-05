//
//  OutputImageViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class OutputImageViewModel: ControlViewModel {
    
    let label: String?
    
    var isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .outputImage
    
    let value: URL
    
    init(id: String = "image_output", label: String? = nil, value: URL) {
        self.label = label
        self.value = value
        self.id = id
    }
}
