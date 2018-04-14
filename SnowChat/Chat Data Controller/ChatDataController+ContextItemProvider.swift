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
            
            self.cancelConversationWithConfirmationIfNeeded(presentingController: viewController, sender: sender) {
                self.chatterbox.cancelConversation()
            }
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
    
    fileprivate func agentChatAction(presentingController: UIViewController, sender: UIBarButtonItem) -> UIAlertAction? {
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
            self.cancelConversationWithConfirmationIfNeeded(presentingController: presentingController, sender: sender) {
                self.chatterbox.transferToLiveAgent()
            }
        }
        
        let alreadyContactingAgent = chatterbox.state == .agentConversation || chatterbox.state == .waitingForAgent
        
        actionItem.isEnabled = supportQueueInfo.active && !alreadyContactingAgent
        
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
        if let agent = agentChatAction(presentingController: presentingController, sender: sender) {
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
    
    private func cancelConversationWithConfirmationIfNeeded(presentingController: UIViewController, sender: UIBarButtonItem, execute: @escaping () -> Void ) {
        if chatterbox.state == .agentConversation || chatterbox.state == .userConversation {
            
            let title = NSLocalizedString("Do you want to end the current conversation?", comment: "Alert title when about to end a conversation to transfer to an agent")
            let affirmative = NSLocalizedString("End Conversation", comment: "Affirmative button for ending current conversation")
            let negative = NSLocalizedString("Cancel", comment: "Negative button for ending current conversation")
            
            let style: UIAlertControllerStyle
            let iPadRegular = presentingController.traitCollection.horizontalSizeClass == .regular && presentingController.traitCollection.verticalSizeClass == .regular
            
            // actionSheet does not work well for the iPad as it drops the 'cancel' option, and pins it to the button
            // so we make it an alert there, otherwise actionSheet looks good
            if iPadRegular {
                style = .alert
            } else {
                style = .actionSheet
            }
            
            let alertController = UIAlertController(title: title,
                                                    message:nil,
                                                    preferredStyle: style)
            
            let OKAction = UIAlertAction(title: affirmative, style: .destructive) { action in
                execute()
            }
            alertController.addAction(OKAction)
            
            let cancelAction = UIAlertAction(title: negative, style: .cancel) { action in }
            alertController.addAction(cancelAction)
            
            alertController.popoverPresentationController?.barButtonItem = sender
            presentingController.present(alertController, animated: true) { }
        } else {
            execute()
        }
    }
}
