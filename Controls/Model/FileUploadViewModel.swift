//
//  FileUploadViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class FileUploadViewModel: SingleSelectControlViewModel {
    
    enum ItemType: String {
        case image
        case file
    }
    
    // TODO: Introduce struct for it? or use tuple?
    var selectedImageData: Data?
    var imageName: String?
    var itemType: ItemType
    
    override var type: ControlType {
        return .fileUpload
    }
    
    init(id: String, label: String? = nil, required: Bool, itemType type: String) {
        guard let type = ItemType(rawValue: type) else {
            fatalError("unrecognized item type for file upload")
        }
        
        itemType = type
        var items = [PickerItem]()
        if itemType == .image {
            items.append(contentsOf: [PickerItem.takePhotoItem(), PickerItem.photoLibraryItem()])
        }
        
        super.init(id: id, label: label, required: required, items: items, messageDate: nil)
    }
}
