//
//  ChatDataController+ContextItemProvider.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension ChatDataController: ContextItemProvider {
    
    // MARK: Context Menu
    
    func contextMenuItems() -> [ContextMenuItem] {
        let newConversationItem = newConversationMenuItem()
        let supportItem = contactSupportMenuItem()
        let refreshItem = refreshConversationMenuItem()
        let cancelItem = cancelMenuItem()
        
        return [newConversationItem, supportItem, refreshItem, cancelItem]
    }
    
    fileprivate func newConversationMenuItem() -> ContextMenuItem {
        let menuItem = ContextMenuItem(withTitle: NSLocalizedString("New Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("New Conversation menu selected")
            self.chatterbox.cancelConversation()
        }
        return menuItem
    }
    
    fileprivate func refreshConversationMenuItem() -> ContextMenuItem {
        let menuItem = ContextMenuItem(withTitle: NSLocalizedString("Refresh Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("Refresh Conversation menu selected")
            self.syncConversation()
        }
        return menuItem
    }
    
    fileprivate func contactSupportMenuItem() -> ContextMenuItem {
        let menuItem = ContextMenuItem(withTitle: NSLocalizedString("Contact Support", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("Contact Support menu selected")
            self.presentSupportOptions(viewController, sender)
        }
        return menuItem
    }

    fileprivate func cancelMenuItem() -> ContextMenuItem {
        return ContextMenuItem(withTitle: NSLocalizedString("Cancel", comment: "Context Menu Item Title"), style: .cancel, handler: { _, _ in })
    }
    
    // MARK: Support Actions
    
    fileprivate func emailSupportAction() -> UIAlertAction? {
        guard let brandingSettings = chatterbox.session?.settings?.brandingSettings,
              let emailAddress = brandingSettings.supportEmail else { return nil }
        
        let label = brandingSettings.supportEmailLabel ?? NSLocalizedString("Send Email to Customer Support", comment: "Support Menu item: email support")
        let actionItem = UIAlertAction(title: label, style: .default) { action in
            if let emailUrl = URL(string: "mailto://\(emailAddress)") {
                UIApplication.shared.open(emailUrl, options: [:])
            }
        }
        return actionItem
    }
    
    fileprivate func agentChatAction() -> UIAlertAction? {
        guard let brandingSettings = chatterbox.session?.settings?.brandingSettings,
              let supportQueueInfo = chatterbox.supportQueueInfo else { return nil }
        
        var messageToUser: String
        
        if supportQueueInfo.active == true {
            messageToUser = brandingSettings.supportHoursLabel ?? NSLocalizedString("Chat with an Agent", comment: "Support Menu item: default agent chat menu item text")
            let waitTime = supportQueueInfo.averageWaitTime
            messageToUser += ": \(waitTime) wait"
        } else {
            messageToUser = NSLocalizedString("No Chat Agents Currently Available", comment: "Support Menu item: chat with agent when chat is unavailable")
        }
        
        let actionItem = UIAlertAction(title: messageToUser, style: .default) { action in
            self.chatterbox.transferToLiveAgent()
        }
        
        actionItem.isEnabled = supportQueueInfo.active
        return actionItem
    }
    
    fileprivate func callSupportAction() -> UIAlertAction? {
        guard let brandingSettings = chatterbox.session?.settings?.brandingSettings,
              let phoneNumber = brandingSettings.supportPhone,
              let phoneUrl = URL(string: "tel://\(phoneNumber)")else { return nil }
        
        let message = brandingSettings.supportPhoneLabel ?? NSLocalizedString("Call Support", comment: "Support Menu item: call support default menu item text")
        
        let actionItem = UIAlertAction(title: message, style: .default) { action in
            UIApplication.shared.open(phoneUrl, options: [:])
        }
        
        return actionItem
    }
    
    fileprivate func presentSupportOptions(_ presentingController: UIViewController, _ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Support Options", comment: "Title for support options popover"),
                                                message: nil,
                                                preferredStyle: .actionSheet)
        if let agent = agentChatAction() {
            alertController.addAction(agent)
        }
        
        if let call = callSupportAction() {
            alertController.addAction(call)
        }
        
        if let email = emailSupportAction() {
            alertController.addAction(email)
        }
        
        let cancelText = alertController.actions.count > 0 ?
            NSLocalizedString("Cancel", comment: "Cancel Support Menu item") :
            NSLocalizedString("No support options are currently available", comment: "No Support Available Menu item")
        let cancel = UIAlertAction(title: cancelText, style: .cancel)
        
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.barButtonItem = sender
        presentingController.present(alertController, animated: true, completion: nil)
    }
}
