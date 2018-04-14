//
//  ChatDataController+Appearance.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/23/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension ChatDataController {
    
    func applyAppearance() {
        // For some elements we can just use UIAppearance..makes theming life easier
        TopicSelectionTableCell.appearance(whenContainedInInstancesOf: [ConversationViewController.self]).backgroundColor = theme.buttonBackgroundColor
        UITableViewCell.appearance(whenContainedInInstancesOf: [BubbleView.self, ChatMessageViewController.self]).backgroundColor = theme.buttonBackgroundColor
        TopicDividerCell.appearance(whenContainedInInstancesOf: [ConversationViewController.self]).backgroundColor = theme.backgroundColor
        UIView.appearance(whenContainedInInstancesOf: [PickerTableViewCell.self]).backgroundColor = theme.buttonBackgroundColor
        UIView.appearance(whenContainedInInstancesOf: [SelectableViewCell.self]).backgroundColor = theme.buttonBackgroundColor
        GradientView.appearance(whenContainedInInstancesOf: [CarouselViewController.self, BubbleView.self, ChatMessageViewController.self]).backgroundColor = .white
    }
}
