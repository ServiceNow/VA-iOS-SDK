//
//  PickerMetadata.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/19/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

// Used by MultiSelect and Picker messages

enum PickerStyle: String, Codable {
    case carousel
    case list
}

struct CarouselLabeledValue: Codable {
    // TODO: Use LabeledValue here for label and value
    let label: String
    let value: String
    var attachment: String?
}

struct PickerMetadata: Codable {
    let multiSelect: Bool
    let style: PickerStyle
    let openByDefault: Bool
    let required: Bool?
    let itemType: String?
    let label: String
    let options: [CarouselLabeledValue]
}
