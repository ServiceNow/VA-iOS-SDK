//
//  ConsumerTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ConsumerTextMessage: Codable {
    
    let type: String
    let data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String
    }

    init(withData: RichControlData<ControlWrapper>) {
        type = "consumerTextMessage"
        data = withData
    }
}
