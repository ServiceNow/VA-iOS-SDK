//
//  ViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 11/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import SnowChat

class ViewController: UIViewController {

    @IBOutlet weak var testMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RemoveMe.test()

        RemoveMe.testAsync { msg in
            self.testMessage.text = msg
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

