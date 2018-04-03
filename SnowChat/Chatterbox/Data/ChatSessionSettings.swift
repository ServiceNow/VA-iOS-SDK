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
    var messageDelay: Int
    var presenceDelay: Int
    
    var welcomeMessage: String
    var introMessage: String
    var genericErrorMessage: String
    
    init(fromDictionary dictionary: [String: Any]) {
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
        
        welcomeMessage = dictionary["welcome_message"] as? String ?? "Welcome to our Support Chat! How can I help you"
        introMessage = dictionary["top_selection_message"] as? String ?? "You can type your request below, or use the button to see everything that I can assist you with."
        genericErrorMessage = dictionary["error_message"] as? String ?? "An unrecoverable error has occurred."
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
     */
    
    var supportEmailLabel: String?
    var supportEmail: String?
    var supportPhoneLabel: String?
    var supportPhone: String?
    var supportHoursLabel: String?
    
    var headerLabel: String?
    
    var virtualAgentLogo: String?
    var virtualAgentProfileId: String?
    
    // swiftlint:disable:next redundant_optional_initialization
    var theme: Theme? = nil // Codable requires default value :/
    
    private enum CodingKeys: String, CodingKey {
        case supportEmailLabel
        case supportEmail
        case supportPhoneLabel
        case supportPhone
        case supportHoursLabel
        case headerLabel
        case virtualAgentLogo
        case virtualAgentProfileId
        
        // NOTE: not including color map for now - would need a custom decoder for UIColor
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        supportEmailLabel = dictionary["support_email_label"] as? String
        supportEmail = dictionary["support_email"] as? String
        supportPhoneLabel = dictionary["support_phone_label"] as? String
        supportHoursLabel = dictionary["support_hours_label"] as? String
        supportPhone = dictionary["support_phone"] as? String
        
        headerLabel = dictionary["header_label"] as? String
        virtualAgentLogo = dictionary["va_logo"] as? String
        virtualAgentProfileId = dictionary["va_profile"] as? String
        
        theme = Theme(dictionary: dictionary)
    }
}

struct VirtualAgentSettings: Codable {
    var avatar: String?
    
    init(fromDictionary dictionary:  [String: Any]) {
        avatar = dictionary["avatar"] as? String
    }
}

struct LiveAgentSettings: Codable {
    init(fromDictionary dictionary:  [String: Any]) {
    }
}
