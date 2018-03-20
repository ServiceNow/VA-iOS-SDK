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
            let settingsDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
        
            let settings = ChatSessionSettings(fromDictionary: settingsDictionary)

            assertBrandingSettings(settingsDictionary, settings)
            assertGeneralSettings(settingsDictionary, settings)
            assertVirtualAgentSettings(settingsDictionary, settings)
            assertLiveAgentSettings(settingsDictionary, settings)
            
        } catch {
            XCTAssertFalse(true)
        }
    }

    fileprivate func assertVirtualAgentSettings(_ settingsDictionary: NSDictionary, _ settings: ChatSessionSettings) {
        let virtualAgentDictionary = settingsDictionary["virtualAgentProfile"] as! NSDictionary
        XCTAssertNotNil(virtualAgentDictionary)

        XCTAssertEqual(settings.virtualAgentSettings?.avatar, virtualAgentDictionary.object(forKey: "avatar") as? String)
        XCTAssertEqual(settings.virtualAgentSettings?.name, virtualAgentDictionary.object(forKey: "name") as? String)

    }
    
    fileprivate func assertLiveAgentSettings(_ settingsDictionary: NSDictionary, _ settings: ChatSessionSettings) {
        let liveAgentDictionary = settingsDictionary["liveAgentSetup"] as! NSDictionary
        XCTAssertNotNil(liveAgentDictionary)
        
        // TODO: add live agent settions and tests when needed
    }
    
    fileprivate func assertGeneralSettings(_ settingsDictionary: NSDictionary, _ settings: ChatSessionSettings) {
        let generalDictionary = settingsDictionary["generalSettings"] as! NSDictionary
        XCTAssertNotNil(generalDictionary)

        XCTAssertEqual(settings.generalSettings?.botName, generalDictionary.object(forKey: "bot_name") as? String)
        XCTAssertEqual(settings.generalSettings?.liveAgentHandoffMessage, generalDictionary.object(forKey: "live_agent_handoff") as? String)
        XCTAssertEqual(settings.generalSettings?.introMessage, generalDictionary.object(forKey: "intro_msg") as? String)
        XCTAssertEqual(settings.generalSettings?.vendorName, generalDictionary.object(forKey: "vendor_name") as? String)
        XCTAssertEqual(settings.generalSettings?.presenceDelay, Int((generalDictionary.object(forKey: "type_presence_delay") as? String)!))
        XCTAssertEqual(settings.generalSettings?.genericErrorMessage, generalDictionary.object(forKey: "generic_error") as? String)

        XCTAssertEqual(settings.generalSettings?.messageDelay, Int((generalDictionary.object(forKey: "msg_delay") as? String)!))


    }
    
    fileprivate func assertBrandingSettings(_ settingsDictionary: NSDictionary, _ settings: ChatSessionSettings) {
        let brandingDictionary = settingsDictionary["brandingSettings"] as! NSDictionary
        XCTAssertNotNil(brandingDictionary)

        XCTAssertEqual(settings.brandingSettings?.headerLabel, brandingDictionary.object(forKey: "header_label") as? String)
        XCTAssertEqual(settings.brandingSettings?.supportPhone, brandingDictionary.object(forKey: "support_phone") as? String)
        XCTAssertEqual(settings.brandingSettings?.supportEmailLabel, brandingDictionary.object(forKey: "support_email_label") as? String)
        XCTAssertEqual(settings.brandingSettings?.supportHoursLabel, brandingDictionary.object(forKey: "support_hours_label") as? String)
        XCTAssertEqual(settings.brandingSettings?.supportPhoneLabel, brandingDictionary.object(forKey: "support_phone_label") as? String)
        
        XCTAssertEqual(settings.brandingSettings?.headerBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "header_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.loadingAnimationColor, UIColor(hexValue: brandingDictionary.object(forKey: "load_animation_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.categoryFontColor, UIColor(hexValue: brandingDictionary.object(forKey: "category_font_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.bubbleBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "bubble_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.botBubbleBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "bot_bubble_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.disabledLinkColor, UIColor(hexValue: brandingDictionary.object(forKey: "disabled_link_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.agentBubbleBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "agent_bubble_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.menuIconColor, UIColor(hexValue: brandingDictionary.object(forKey: "menu_icon_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.separatorColor, UIColor(hexValue: brandingDictionary.object(forKey: "seperator_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.linkColor, UIColor(hexValue: brandingDictionary.object(forKey: "link_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.bubbleFontColor, UIColor(hexValue: brandingDictionary.object(forKey: "bubble_font_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.agentBubbleFontColor, UIColor(hexValue: brandingDictionary.object(forKey: "agent_bubble_font_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.headerFontColor, UIColor(hexValue: brandingDictionary.object(forKey: "header_font_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.botBubbleFontColor, UIColor(hexValue: brandingDictionary.object(forKey: "bot_bubble_font_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.categoryBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "category_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.systemMessageColor, UIColor(hexValue: brandingDictionary.object(forKey: "system_message_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.timestampColor, UIColor(hexValue: brandingDictionary.object(forKey: "timestamp_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.backgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.buttonBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "button_bg_color") as! String))
        XCTAssertEqual(settings.brandingSettings?.inputBackgroundColor, UIColor(hexValue: brandingDictionary.object(forKey: "input_bg_color") as! String))
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

