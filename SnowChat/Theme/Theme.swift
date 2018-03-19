//
//  Theme.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ColorSettings {
    static let categoryFontColor = "category_font_color"
    static let linkColor = "link_color"
    static let timestampColor = "timestamp_color"
    static let inputBackgroundColor = "input_bg_color"
    static let bubbleFontColor = "bubble_font_color"
    static let bubbleBackgroundColor = "bubble_bg_color"
    static let agentBubbleFontColor = "agent_bubble_font_color"
    static let agentBubbleBackgroundColor = "agent_bubble_bg_color"
    static let botBubbleFontColor = "bot_bubble_font_color"
    static let botBubbleBackgroundColor = "bot_bubble_bg_color"
    static let backgroundColor = "bg_color"
    static let loadingAnimationColor = "load_animation_color"
    static let separatorColor = "seperator_color"
    static var categoryBackgroundColor = "category_bg_color"
    static let buttonBackgroundColor = "button_bg_color"
    static let disabledLinkColor = "disabled_link_color"
    static let headerBackgroundColor = "header_bg_color"
    static let menuIconColor = "menu_icon_color"
    static let systemMessageColor = "system_message_color"
    static let headerFontColor = "header_font_color"
}

class Theme {
    private var colorPropertiesMap = [String : UIColor]()
    
    init(dictionary: [String : Any]?) {
        dictionary?.keys.forEach { [weak self] key in
            if let value = dictionary?[key] as? String {
                self?.colorPropertiesMap[key] = UIColor(hexValue: value)
            }
        }
    }
    
    var categoryFontColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.categoryFontColor] else {
            return UIColor.categoryFontColor
        }
        
        return color
    }
    
    var linkColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.linkColor] else {
            return UIColor.defaultLinkColor
        }
        
        return color
    }
    
    var timestampColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.timestampColor] else {
            return UIColor.defaultTimestampColor
        }
        
        return color
    }
    
    var inputBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.inputBackgroundColor] else {
            return UIColor.defaultInputBackgroundColor
        }
        
        return color
    }
    
    var bubbleFontColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.bubbleFontColor] else {
            return UIColor.defaultBubbleFontColor
        }
        
        return color
    }
    
    var bubbleBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.bubbleBackgroundColor] else {
            return UIColor.defaultBubbleBackgroundColor
        }
        return color
    }
    
    var agentBubbleFontColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.agentBubbleFontColor] else {
            return UIColor.defaultBubbleFontColor
        }
        
        return color
    }
    
    var agentBubbleBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.agentBubbleBackgroundColor] else {
            return UIColor.defaultAgentBubbleBackgroundColor
        }
        
        return color
    }
    
    var botBubbleFontColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.botBubbleFontColor] else {
            return UIColor.defaultBotBubbleFontColor
        }
        
        return color
    }
    
    var botBubbleBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.botBubbleBackgroundColor] else {
            return UIColor.defaultBotBubbleBackgroundColor
        }
        
        return color
    }
    
    var backgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.backgroundColor] else {
            return UIColor.defaultBackgroundColor
        }
        
        return color
    }
    
    var loadingAnimationColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.loadingAnimationColor] else {
            return UIColor.defaultLoadingAnimationColor
        }
        
        return color
    }
    
    var separatorColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.separatorColor] else {
            return UIColor.defaultSeparatorColor
        }
        
        return color
    }
    
    var categoryBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.categoryBackgroundColor] else {
            return UIColor.defaultCategoryBackgroundColor
        }
        
        return color
    }
    
    var buttonBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.buttonBackgroundColor] else {
            return UIColor.defaultButtonBackgroundColor
        }
        
        return color
    }
    
    var disabledLinkColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.disabledLinkColor] else {
            return UIColor.defaultDisabledLinkColor
        }
        
        return color
    }
    
    var headerBackgroundColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.headerBackgroundColor] else {
            return UIColor.defaultHeaderBackgroundColor
        }
        
        return color
    }
    
    var menuIconColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.menuIconColor] else {
            return UIColor.defaultMenuIconColor
        }
        
        return color
    }
    
    var systemMessageColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.systemMessageColor] else {
            return UIColor.defaultSystemMessageColor
        }
        
        return color
    }
    
    var headerFontColor: UIColor {
        guard let color = colorPropertiesMap[ColorSettings.headerFontColor] else {
            return UIColor.defaultHeaderFontColor
        }
        
        return color
    }
}
