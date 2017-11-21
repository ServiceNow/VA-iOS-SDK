//
//  AMBTestViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import AMBClient

public class AMBTestViewController: UIViewController {
    
    private lazy var manager: APIManager = {
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "https://snowchat.service-now.com")!
        let instance = ServerInstance(instanceURL: url)
        let manager = APIManager(instance: instance)
        return manager
    }()
    
    var subscription: NOWAMBSubscription?

    // MARK: - View Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        manager.logIn(username: "admin", password: "snow2004") { [weak self] success in
            if success {
                self?.setupAMBSubscription()
            } else {
                debugPrint("Failed to log in")
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupAMBSubscription() {
        let allIncidentsChannel = "/rw/default/incident/c3lzX2lkSVNOT1RFTVBUWQ--"
        
        subscription = manager.ambClient.subscribe(allIncidentsChannel) { (subscription, message) in
            debugPrint(message ?? "welp!")
        }
    }

}
