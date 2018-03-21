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
            assertLiveAgentSettings(settingsDictionary, settings)
            
        } catch {
            XCTAssertFalse(true)
        }
    }

    fileprivate func assertVirtualAgentSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let virtualAgentDictionary = settingsDictionary["virtualAgentProfile"] as! [String: Any]
        XCTAssertNotNil(virtualAgentDictionary)

        XCTAssertEqual(settings.virtualAgentSettings?.avatar, virtualAgentDictionary["avatar"] as? String)
        XCTAssertEqual(settings.virtualAgentSettings?.name, virtualAgentDictionary["name"] as? String)

    }
    
    fileprivate func assertLiveAgentSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let liveAgentDictionary = settingsDictionary["liveAgentSetup"] as! [String: Any]
        XCTAssertNotNil(liveAgentDictionary)
        
        // TODO: add live agent settions and tests when needed
    }
    
    fileprivate func assertGeneralSettings(_ settingsDictionary: [String: Any], _ settings: ChatSessionSettings) {
        let generalDictionary = settingsDictionary["generalSettings"] as! [String: Any]
        XCTAssertNotNil(generalDictionary)

        XCTAssertEqual(settings.generalSettings?.botName, generalDictionary["bot_name"] as? String)
        XCTAssertEqual(settings.generalSettings?.liveAgentHandoffMessage, generalDictionary["live_agent_handoff"] as? String)
        XCTAssertEqual(settings.generalSettings?.introMessage, generalDictionary["intro_msg"] as? String)
        XCTAssertEqual(settings.generalSettings?.vendorName, generalDictionary["vendor_name"] as? String)
        XCTAssertEqual(settings.generalSettings?.presenceDelay, Int((generalDictionary["type_presence_delay"] as? String)!))
        XCTAssertEqual(settings.generalSettings?.genericErrorMessage, generalDictionary["generic_error"] as? String)

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
            "support_email": "support@servicenow.com",
            "bot_name": "NowBot",
            "live_agent_handoff": "We will be transferring you to an Agent, when the next available Agent is ready",
            "support_hours": "M-F 9-5 PST",
            "support_phone": "1-800-245-6000",
            "intro_msg": "Hello and welcome to our support chat! How can I help you?",
            "vendor_name": "Service Now",
            "type_presence_delay": "999",
            "generic_error": "There are no agents available right now, Please try again later.",
            "msg_delay": "600"
        },
        "brandingSettings": {
            "header_bg_color": "#fafafa",
            "load_animation_color": "#7f8e9f",
            "category_font_color": "#000",
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
            "support_hours": "M-F 9-5 PST",
            "support_hours_label": "Contact Live Agent",
            "support_phone_label": "Call Support(Daily, 5AM - 11 PM)",
            "bubble_font_color": "#000",
            "agent_bubble_font_color": "#000",
            "header_font_color": "#7f8e9f",
            "bot_bubble_font_color": "#000",
            "category_bg_color": "#7f8e9f",
            "subheader_label": "Servicenow Inc",
            "system_message_color": "#7f8e9f",
            "timestamp_color": "#B8B8B8",
            "va_logo": "1ddddc53dbb743001f4cf9b61d9619ad.iix",
            "bg_color": "#ffffff",
            "support_email": "support@servicenow.com",
            "va_profile": "0ca39ea2872303002ae97e2526cb0b70",
            "button_bg_color": "#fff",
            "input_bg_color": "#fafafa"
        },
        "liveAgentSetup": {
            "vrcontext": [

            ],
            "queues": [
                {
                    "queue": "",
                    "application": "csm"
                },
                {
                    "queue": "",
                    "application": "hr"
                },
                {
                    "queue": "",
                    "application": "itsm"
                },
                {
                    "queue": "",
                    "application": "global"
                }
            ],
            "globalDefaultQueue": "",
            "virtual_agent_enabled": true
        },
        "virtualAgentProfile": {
            "avatar": "1ddddc53dbb743001f4cf9b61d9619ad.iix?t=small"
        }
    }
    """
}

