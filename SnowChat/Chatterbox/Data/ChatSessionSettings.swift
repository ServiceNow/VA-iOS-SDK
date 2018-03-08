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
    
    init(fromDictionary dictionary: NSDictionary) {
        if let general = dictionary["generalSettings"] as? NSDictionary {
            generalSettings = GeneralSettings(fromDictionary: general)
        }
        
        if let branding = dictionary["brandingSettings"] as? NSDictionary {
            brandingSettings = BrandingSettings(fromDictionary: branding)
        }
        
        if let virtualAgent = dictionary["virtualAgentProfile"] as? NSDictionary {
            let avatar = virtualAgent["avatar"] as? String
            let name = virtualAgent["name"] as? String
            virtualAgentSettings = VirtualAgentSettings(avatar: avatar, name: name)
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

    init(fromDictionary dictionary: NSDictionary) {
        botName = dictionary["bot_name"] as? String ?? "ChatBot"
        vendorName = dictionary["vendor_name"] as? String ?? "Vendor"
        
        messageDelay = dictionary["msg_delay"] as? Int ?? 500
        presenceDelay = dictionary["type_presence_delay"] as? Int ?? 1000
        
        introMessage = dictionary["intro_msg"] as? String ?? "Hello and welcome to our support chat! How can I help you?"
        liveAgentHandoffMessage = dictionary["live_agent_handoff"] as? String ?? "We will be transferring you to an Agent when the next available Agent is ready."
        genericErrorMessage = dictionary["generic_error"] as? String ?? "There are no agents available right now. Please try again later."
    }
}

struct BrandingSettings: Codable {
    var supportEmailLabel: String?
    var supportEmail: String?
    var supportPhoneLabel: String?
    var supportPhone: String?
    var supportHoursLabel: String?
    
    init(fromDictionary dictionary: NSDictionary) {
        supportEmailLabel = dictionary["support_email_label"] as? String
        supportEmail = dictionary["support_email"] as? String
        supportPhoneLabel = dictionary["support_phone_label"] as? String
        supportHoursLabel = dictionary["support_hours_label"] as? String
        supportPhone = dictionary["support_phone"] as? String
    }
}

struct VirtualAgentSettings: Codable {
    var avatar: String?
    var name: String?
}

struct LiveAgentSettings: Codable {
    
}
