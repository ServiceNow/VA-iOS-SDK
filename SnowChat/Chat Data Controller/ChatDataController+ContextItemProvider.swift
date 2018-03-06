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
            self.chatterbox.endUserConversation()
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
        guard let emailAddress = chatterbox.session?.settings?.generalSettings?.supportEmail else { return nil }
        
        let actionItem = UIAlertAction(title: NSLocalizedString("Send Email to Customer Support", comment: "Support Menu item: email support"), style: .default) { action in
            if let emailUrl = URL(string: "mailto://\(emailAddress)") {
                UIApplication.shared.open(emailUrl, options: [:])
            }
        }
        return actionItem
    }
    
    fileprivate func agentChatAction() -> UIAlertAction? {
        guard let supportQueueInfo = chatterbox.supportQueueInfo  else { return nil }
        
        var messageToUser = NSLocalizedString("No Chat Agents Currently Available", comment: "Support Menu item: chat with agent when chat is unavailable")
        
        if supportQueueInfo.active == true {
            messageToUser = NSLocalizedString("Chat with an Agent", comment: "Support Menu item: chat with agent")
            let waitTime = supportQueueInfo.averageWaitTime
            messageToUser += ": \(waitTime) wait"
        }
        
        let actionItem = UIAlertAction(title: messageToUser, style: .default) { action in
            self.chatterbox.transferToLiveAgent()
        }
        
        actionItem.isEnabled = supportQueueInfo.active
        return actionItem
    }
    
    fileprivate func callSupportAction() -> UIAlertAction? {
        guard let generalSettings = chatterbox.session?.settings?.generalSettings else { return nil }
        
        var message = NSLocalizedString("Call Support: ", comment: "Support Menu item: call support")
        if let hours = generalSettings.supportHours {
            message += hours
        }
        
        let actionItem = UIAlertAction(title: message, style: .default) { action in
            if let phoneNumber = generalSettings.supportPhone, let phoneUrl = URL(string: "tel://\(phoneNumber)") {
                UIApplication.shared.open(phoneUrl, options: [:])
            }
        }
        return actionItem
    }
    
    fileprivate func presentSupportOptions(_ presentingController: UIViewController, _ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Support Options", comment: "Title for support options popover"),
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        if let email = emailSupportAction() {
            alertController.addAction(email)
        }
        
        if let agent = agentChatAction() {
            alertController.addAction(agent)
        }
        
        if let call = callSupportAction() {
            alertController.addAction(call)
        }
        
        let count = alertController.actions.count
        
        let cancel = UIAlertAction(title: count > 0 ?
            NSLocalizedString("Cancel", comment: "Cancel Support Menu item") :
            NSLocalizedString("No Support Options Available", comment: "No Support Available Menu item"),
                                   style: .cancel)
        alertController.addAction(cancel)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        presentingController.present(alertController, animated: true, completion: nil)
    }
}
