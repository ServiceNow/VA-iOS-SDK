//
//  UIViewController+ModalNavigation.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension UIViewController {
    @objc func finishModalPresentation(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
