//
//  InputImageViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class InputImageViewModel: SingleSelectControlViewModel {
    
    var selectedImageData: Data?
    
    override var type: ControlType {
        return .inputImage
    }
    
    init(id: String, label: String? = nil, required: Bool) {
        super.init(id: id, label: label, required: required, items: [PickerItem.takePhotoItem(), PickerItem.photoLibraryItem()])
    }
}
