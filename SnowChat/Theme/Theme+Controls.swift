//
//  Theme+Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/20/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

// MARK: - Controls theme
// Helper object/adapter that conforms to Controls theme protocol

class ControlVisualTheme: ControlTheme {
    var backgroundColor: UIColor
    var buttonBackgroundColor: UIColor
    var selectedBackgroundColor: UIColor
    var borderColor: UIColor
    var fontColor: UIColor
    var actionFontColor: UIColor
    var headerBackgroundColor: UIColor
    var headerFontColor: UIColor
    var dividerColor: UIColor
    var linkColor: UIColor
    
    init(backgroundColor: UIColor, buttonBackgroundColor: UIColor, borderColor: UIColor, fontColor: UIColor, headerBackgroundColor: UIColor, headerFontColor: UIColor, linkColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.borderColor = borderColor
        self.fontColor = fontColor
        self.headerBackgroundColor = headerBackgroundColor
        self.headerFontColor = headerFontColor
        self.dividerColor = Theme.dividerColor
        self.selectedBackgroundColor = Theme.controlSelectedBackgroundColor
        self.actionFontColor = Theme.controlActionFontColor
        self.linkColor = linkColor
    }
}

// MARK: - ControlTheme utils

extension Theme {
    func controlThemeForAgent() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: agentBubbleBackgroundColor,
                                  buttonBackgroundColor: buttonBackgroundColor,
                                  borderColor: agentBubbleBackgroundColor,
                                  fontColor: agentBubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor,
                                  linkColor: linkColor)
    }
    
    func controlThemeForBot() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: botBubbleBackgroundColor,
                                  buttonBackgroundColor: buttonBackgroundColor,
                                  borderColor: botBubbleBackgroundColor,
                                  fontColor: botBubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor,
                                  linkColor: linkColor)
    }
    
    func controlTheme() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: bubbleBackgroundColor,
                                  buttonBackgroundColor: buttonBackgroundColor,
                                  borderColor: bubbleBackgroundColor,
                                  fontColor: bubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor,
                                  linkColor: linkColor)
    }
}
