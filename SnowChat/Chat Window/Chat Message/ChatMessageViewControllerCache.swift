//
//  ChatMessageViewControllerCache.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

// Each cell will have its own view controller to handle each message
// Idea taken from: http://khanlou.com/2015/04/view-controllers-in-cells/

class ChatMessageViewControllerCache {
    
    private var viewControllersToReuse = Set<ChatMessageViewController>()
    
    func cachedViewController(movedToParentViewController parent: UIViewController) -> ChatMessageViewController {
        let messageViewController: ChatMessageViewController
        if let firstUnusedController = viewControllersToReuse.first {
            messageViewController = firstUnusedController
            viewControllersToReuse.remove(messageViewController)
        } else {
            messageViewController = ChatMessageViewController(nibName: "ChatMessageViewController", bundle: Bundle(for: type(of: self)))
        }

        messageViewController.willMove(toParentViewController: parent)
        parent.addChildViewController(messageViewController)
        return messageViewController
    }
    
    func cacheViewController(_ viewController: ChatMessageViewController) {
        viewController.removeFromParentViewController()
        viewController.prepareForReuse()
        viewControllersToReuse.insert(viewController)
    }
    
    func removeAll() {
        viewControllersToReuse.removeAll()
    }
}
