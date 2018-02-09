//
//  StartTopicViewModel.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class StartTopicViewModel: ControlViewModel {
    
    let label: String?
    let isRequired: Bool = true
    let id: String
    let type: ControlType = .startTopicDivider
    
    let date: Date
    
    init(id: String, date: Date) {
        self.label = nil
        self.id = id
        self.date = date
    }
}
