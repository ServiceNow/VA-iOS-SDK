//
//  ViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 11/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let debugStoryboard = UIStoryboard(name: "Debug", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let debugViewController = debugStoryboard.instantiateInitialViewController() {
            present(debugViewController, animated: false, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
