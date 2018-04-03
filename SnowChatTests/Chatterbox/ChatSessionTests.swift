//
//  ChatSessionTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest

@testable import SnowChat

class ChatSessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSettings() {
        guard let data = settingsJSON.data(using: .utf8) else {
            XCTAssertFalse(true)
            return
        }
        
        do {
            let settingsDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        
            let settings = ChatSessionSettings(fromDictionary: settingsDictionary)

            assertBrandingSettings(settingsDictionary, settings)
            assertGeneralSettings(settingsDictionary, settings)
            assertVirtualAgentSettings(settingsDictionary, settings)
            
        } catch {
            XCTAssertFalse(true)
        }
    }

    fileprivate func assertVirtualAgentSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let virtualAgentDictionary = settingsDictionary["virtualAgentProfile"] as! [String: Any]
        XCTAssertNotNil(virtualAgentDictionary)

        XCTAssertEqual(settings.virtualAgentSettings?.avatar, virtualAgentDictionary["avatar"] as? String)
    }
    
    fileprivate func assertGeneralSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let generalDictionary = settingsDictionary["generalSettings"] as! [String: Any]
        XCTAssertNotNil(generalDictionary)

        XCTAssertEqual(settings.generalSettings?.welcomeMessage, generalDictionary["welcome_message"] as? String)
        XCTAssertEqual(settings.generalSettings?.genericErrorMessage, generalDictionary["error_message"] as? String)
        XCTAssertEqual(settings.generalSettings?.introMessage, generalDictionary["top_selection_message"] as? String)
        
        XCTAssertEqual(settings.generalSettings?.presenceDelay, Int((generalDictionary["type_presence_delay"] as? String)!))
        XCTAssertEqual(settings.generalSettings?.messageDelay, Int((generalDictionary["msg_delay"] as? String)!))
    }
    
    fileprivate func assertBrandingSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let brandingDictionary = settingsDictionary["brandingSettings"] as! [String: Any]
        XCTAssertNotNil(brandingDictionary)

        XCTAssertEqual(settings.brandingSettings?.headerLabel, brandingDictionary["header_label"] as? String)
        XCTAssertEqual(settings.brandingSettings?.supportPhone, brandingDictionary["support_phone"] as? String)
        XCTAssertEqual(settings.brandingSettings?.supportEmailLabel, brandingDictionary["support_email_label"] as? String)
        XCTAssertEqual(settings.brandingSettings?.supportHoursLabel, brandingDictionary["support_hours_label"] as? String)
        XCTAssertEqual(settings.brandingSettings?.supportPhoneLabel, brandingDictionary["support_phone_label"] as? String)
    }

    let settingsJSON = """
    {
        "generalSettings": {
            "error_message": "An unrecoverable error has occurred.",
            "type_presence_delay": "1000",
            "welcome_message": "Welcome to our support chat! How can I help you?",
            "msg_delay": "500",
            "top_selection_message": "You can type your request below, or use the button to see everything that I can assist you with"
        },
        "brandingSettings": {
            "header_bg_color": "#fafafa",
            "load_animation_color": "#7f8e9f",
            "category_font_color": "#6d6d72",
            "bubble_bg_color": "#e6e6e6",
            "support_phone": "1-800-245-6000",
            "bot_bubble_bg_color": "#c3ddef",
            "disabled_link_color": "#B8B8B8",
            "agent_bubble_bg_color": "#c3ddef",
            "header_label": "Now Support",
            "menu_icon_color": "#7f8e9f",
            "seperator_color": "#B8B8B8",
            "support_email_label": "Send Email to Customer Support",
            "link_color": "#008bff",
            "support_hours_label": "Contact Live Agent",
            "support_phone_label": "Call Support(Daily, 5AM - 11 PM)",
            "bubble_font_color": "#000",
            "agent_bubble_font_color": "#000",
            "header_font_color": "#7f8e9f",
            "bot_bubble_font_color": "#000",
            "category_bg_color": "#efeff4",
            "system_message_color": "#7f8e9f",
            "timestamp_color": "#B8B8B8",
            "va_logo": "1ddddc53dbb743001f4cf9b61d9619ad.iix",
            "bg_color": "#ffffff",
            "support_email": "support@servicenow.com",
            "va_profile": "0ca39ea2872303002ae97e2526cb0b70",
            "button_bg_color": "#fff",
            "input_bg_color": "#fafafa"
        },
        "virtualAgentProfile": {
            "avatar": "1ddddc53dbb743001f4cf9b61d9619ad.iix?t=small"
        },
        "textDirection": "ltr"
    }
    """
}

