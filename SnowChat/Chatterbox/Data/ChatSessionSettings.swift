//
//  ChatSessionSettings.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ChatSessionSettings: Codable {
    var generalSettings: GeneralSettings?
    var brandingSettings: BrandingSettings?
    var virtualAgentSettings: VirtualAgentSettings?
    var liveAgentSettings: LiveAgentSettings?
    
    private enum CodingKeys: String, CodingKey {
        case generalSettings
        case brandingSettings
        case virtualAgentSettings
        case liveAgentSettings
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        if let general = dictionary["generalSettings"] as? [String: Any] {
            generalSettings = GeneralSettings(fromDictionary: general)
        }
        
        if let branding = dictionary["brandingSettings"] as?  [String: Any] {
            brandingSettings = BrandingSettings(fromDictionary: branding)
        }
        
        if let virtualAgent = dictionary["virtualAgentProfile"] as?  [String: Any] {
            virtualAgentSettings = VirtualAgentSettings(fromDictionary: virtualAgent)
        }
        
        if let liveAgent = dictionary["liveAgentSetup"] as?  [String: Any] {
            liveAgentSettings = LiveAgentSettings(fromDictionary: liveAgent)
        }

    }
}

struct GeneralSettings: Codable {
    var botName: String
    var vendorName: String
    var messageDelay: Int
    var presenceDelay: Int
    
    var introMessage: String
    var liveAgentHandoffMessage: String
    var genericErrorMessage: String

    init(fromDictionary dictionary: [String: Any]) {
        botName = dictionary["bot_name"] as? String ?? "ChatBot"
        vendorName = dictionary["vendor_name"] as? String ?? "Vendor"
        
        if let strMessageDelay = dictionary["msg_delay"] as? String {
            messageDelay = Int(strMessageDelay) ?? 500
        } else {
            messageDelay = 500
        }
        
        if let strPresenceDelay = dictionary["type_presence_delay"] as? String {
            presenceDelay = Int(strPresenceDelay) ?? 1000
        } else {
            presenceDelay = 1000
        }
        
        introMessage = dictionary["intro_msg"] as? String ?? "Hello and welcome to our support chat! How can I help you?"
        liveAgentHandoffMessage = dictionary["live_agent_handoff"] as? String ?? "We will be transferring you to an Agent when the next available Agent is ready."
        genericErrorMessage = dictionary["generic_error"] as? String ?? "There are no agents available right now. Please try again later."
    }
}

struct BrandingSettings: Codable {
    /* incoming values (from sessionSettings.brandingSettings)
     - key : category_font_color
     - key : link_color
     - key : timestamp_color
     - key : input_bg_color
     - key : bubble_font_color
     - key : bubble_bg_color
     - key : agent_bubble_font_color
     - key : agent_bubble_bg_color
     - key : bot_bubble_font_color
     - key : bot_bubble_bg_color
     - key : bg_color
     - key : load_animation_color
     - key : seperator_color
     - key : category_bg_color
     - key : button_bg_color
     - key : disabled_link_color
     - key : header_bg_color
     - key : menu_icon_color
     - key : system_message_color
     - key : header_font_color
     - key : header_label
     - key : subheader_label
     - key : va_logo
     - key : va_profile
     - key : support_hours_label
     - key : support_phone_label
     - key : support_phone
     - key : support_email_label
     - key : support_email
     - key : support_hours (obsolete)
     */

    var colorPropertiesMap: [String : UIColor?] = [
        "category_font_color" : nil,
        "link_color" : nil,
        "timestamp_color" : nil,
        "input_bg_color" : nil,
        "bubble_font_color" : nil,
        "bubble_bg_color" : nil,
        "agent_bubble_font_color" : nil,
        "agent_bubble_bg_color" : nil,
        "bot_bubble_font_color" : nil,
        "bot_bubble_bg_color" : nil,
        "bg_color" : nil,
        "load_animation_color" : nil,
        "seperator_color" : nil,
        "category_bg_color" : nil,
        "button_bg_color" : nil,
        "disabled_link_color" : nil,
        "header_bg_color" : nil,
        "menu_icon_color" : nil,
        "system_message_color" : nil,
        "header_font_color" : nil
    ]
    
    var supportEmailLabel: String?
    var supportEmail: String?
    var supportPhoneLabel: String?
    var supportPhone: String?
    var supportHoursLabel: String?
    
    var headerLabel: String?
    var subHeaderLabel: String?
    
    var virtualAgentLogo: String?
    var virtualAgentProfileId: String?
    
    private enum CodingKeys: String, CodingKey {
        case supportEmailLabel
        case supportEmail
        case supportPhoneLabel
        case supportPhone
        case supportHoursLabel
        case headerLabel
        case subHeaderLabel
        case virtualAgentLogo
        case virtualAgentProfileId
        
        // NOTE: not including color map for now - would need a custom decoder for UIColor
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
    
    init(fromDictionary dictionary: [String: Any]) {
        supportEmailLabel = dictionary["support_email_label"] as? String
        supportEmail = dictionary["support_email"] as? String
        supportPhoneLabel = dictionary["support_phone_label"] as? String
        supportHoursLabel = dictionary["support_hours_label"] as? String
        supportPhone = dictionary["support_phone"] as? String
        
        headerLabel = dictionary["header_label"] as? String
        subHeaderLabel = dictionary["subheader_label"] as? String
        virtualAgentLogo = dictionary["va_logo"] as? String
        virtualAgentProfileId = dictionary["va_profile"] as? String
        
        initColors(dictionary)
    }
    
    private mutating func initColors(_ dictionary: [String: Any]) {
        colorPropertiesMap.keys.forEach { key in
            if let value = dictionary[key] as? String {
                colorPropertiesMap[key] = UIColor(hexValue: value)
            }
        }
    }
}

struct VirtualAgentSettings: Codable {
    var avatar: String?
    var name: String?
    
    init(fromDictionary dictionary:  [String: Any]) {
        avatar = dictionary["avatar"] as? String
        name = dictionary["name"] as? String
    }
}

struct LiveAgentSettings: Codable {
    init(fromDictionary dictionary:  [String: Any]) {
    }
}
