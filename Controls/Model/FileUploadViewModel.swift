//
//  FileUploadViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class FileUploadViewModel: SingleSelectControlViewModel {
    
    // TODO: Introduce struct for it? or use tuple?
    var selectedImageData: Data?
    var imageName: String?
    
    override var type: ControlType {
        return .fileUpload
    }
    
    init(id: String, label: String? = nil, required: Bool) {
        super.init(id: id, label: label, required: required, items: [PickerItem.takePhotoItem(), PickerItem.photoLibraryItem()])
    }
}
