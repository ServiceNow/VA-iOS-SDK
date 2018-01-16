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
    
    private(set) var viewControllersByIndexPath = [IndexPath : ChatMessageViewController]()
    private var viewControllersToReuse = Set<ChatMessageViewController>()
    
    func getViewController(for indexPath: IndexPath, movedToParentViewController parent: UIViewController) -> ChatMessageViewController {
        let messageViewController: ChatMessageViewController
        if let firstUnusedController = viewControllersToReuse.first {
            messageViewController = firstUnusedController
            viewControllersToReuse.remove(messageViewController)
        } else {
            messageViewController = ChatMessageViewController(nibName: "ChatMessageViewController", bundle: Bundle(for: type(of: self)))
        }
        
        viewControllersByIndexPath[indexPath] = messageViewController
        messageViewController.willMove(toParentViewController: parent)
        parent.addChildViewController(messageViewController)
        return messageViewController
    }
    
    func removeViewController(at indexPath: IndexPath) {
        guard let messageViewController = viewControllersByIndexPath[indexPath] else {
            return
        }
        
        messageViewController.removeFromParentViewController()
        messageViewController.prepareForReuse()
        viewControllersByIndexPath.removeValue(forKey: indexPath)
        viewControllersToReuse.insert(messageViewController)
    }
}
