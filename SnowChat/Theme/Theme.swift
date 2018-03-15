//
//  Theme.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class Theme {
    
    private var colorPropertiesMap = [String : UIColor]()
    
    init(dictionary: [String : String]) {
        dictionary.keys.forEach { [weak self] key in
            if let value = dictionary[key] {
                self?.colorPropertiesMap[key] = UIColor(hexValue: value)
            }
        }
    }
    
    var categoryFontColor: UIColor? {
        guard let color = colorPropertiesMap["category_font_color"] else { return nil }
        return color
    }
    
    var linkColor: UIColor? {
        guard let color = colorPropertiesMap["link_color"] else { return nil }
        return color
    }
    
    var timestampColor: UIColor? {
        guard let color = colorPropertiesMap["timestamp_color"] else { return nil }
        return color
    }
    
    var inputBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["input_bg_color"] else { return nil }
        return color
    }
    
    var bubbleFontColor: UIColor? {
        guard let color = colorPropertiesMap["bubble_font_color"] else { return nil }
        return color
    }
    
    var bubbleBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["bubble_bg_color"] else { return nil }
        return color
    }
    
    var agentBubbleFontColor: UIColor? {
        guard let color = colorPropertiesMap["agent_bubble_font_color"] else { return nil }
        return color
    }
    
    var agentBubbleBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["agent_bubble_bg_color"] else { return nil }
        return color
    }
    
    var botBubbleFontColor: UIColor? {
        guard let color = colorPropertiesMap["bot_bubble_font_color"] else { return nil }
        return color
    }
    
    var botBubbleBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["bot_bubble_bg_color"] else { return nil }
        return color
    }
    
    var backgroundColor: UIColor? {
        guard let color = colorPropertiesMap["bg_color"] else { return nil }
        return color
    }
    
    var loadingAnimationColor: UIColor? {
        guard let color = colorPropertiesMap["load_animation_color"] else { return nil }
        return color
    }
    
    var separatorColor: UIColor? {
        guard let color = colorPropertiesMap["seperator_color"] else { return nil } // NOTE misspelling of key!
        return color
    }
    
    var categoryBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["category_bg_color"] else { return nil }
        return color
    }
    
    var buttonBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["button_bg_color"] else { return nil }
        return color
    }
    
    var disabledLinkColor: UIColor? {
        guard let color = colorPropertiesMap["disabled_link_color"] else { return nil }
        return color
    }
    
    var headerBackgroundColor: UIColor? {
        guard let color = colorPropertiesMap["header_bg_color"] else { return nil }
        return color
    }
    
    var menuIconColor: UIColor? {
        guard let color = colorPropertiesMap["menu_icon_color"] else { return nil }
        return color
    }
    
    var systemMessageColor: UIColor? {
        guard let color = colorPropertiesMap["system_message_color"] else { return nil }
        return color
    }
    
    var headerFontColor: UIColor? {
        guard let color = colorPropertiesMap["header_font_color"] else { return nil }
        return color
    }
}
