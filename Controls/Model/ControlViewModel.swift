//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// base model for all UIControl models
protocol ControlViewModel {
    
//    enum CodingKeys: String, CodingKey {
//        case title = "label"
//        case required
//        case richControl
//        
//    }
//    
//    required init(from decoder: Decoder) throws {
//        let values = try! decoder.container(keyedBy: CodingKeys.self)
//        title = try values.decode(String.self, forKey: .title)
//        isRequired = try values.decode(Bool.self, forKey: .required)
//    }
    
    // title of the control
    var title: String? { get set }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool? { get set }
}
