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
    
    var borderColor: UIColor
    
    var fontColor: UIColor
    
    var headerBackgroundColor: UIColor
    
    var headerFontColor: UIColor
    
    var dividerColor: UIColor
    
    init(backgroundColor: UIColor, borderColor: UIColor, fontColor: UIColor, headerBackgroundColor: UIColor, headerFontColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.fontColor = fontColor
        self.headerBackgroundColor = headerBackgroundColor
        self.headerFontColor = headerFontColor
        self.dividerColor = .dividerColor
    }
}

// MARK: - ControlTheme utils

extension Theme {
    func controlThemeForAgent() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: agentBubbleBackgroundColor,
                                  borderColor: agentBubbleBackgroundColor,
                                  fontColor: agentBubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor)
    }
    
    func controlThemeForBot() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: botBubbleBackgroundColor,
                                  borderColor: botBubbleBackgroundColor,
                                  fontColor: botBubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor)
    }
    
    func controlTheme() -> ControlTheme {
        return ControlVisualTheme(backgroundColor: bubbleBackgroundColor,
                                  borderColor: bubbleBackgroundColor,
                                  fontColor: bubbleFontColor,
                                  headerBackgroundColor: headerBackgroundColor,
                                  headerFontColor: headerFontColor)
    }
}
