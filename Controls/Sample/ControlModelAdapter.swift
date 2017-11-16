//
//  ControlModelAdapter.swift.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class PickerControlViewModelAdapter {
    
    class func viewModel() -> BooleanControlViewModel {
        
//        if let url = Bundle(identifier: "com.servicenow.snowchat").url(forResource: "samplePicker", withExtension: "json"),
//            let data = try? Data(contentsOf: url),
//            let modelObject = try? JSONDecoder().decode(type(of: model).self, from: data) {
//            
//        }
        
        let booleanViewModel = BooleanControlViewModel()
        return booleanViewModel
    }
}
