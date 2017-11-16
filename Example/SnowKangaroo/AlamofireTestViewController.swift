//
//  AlamofireTestViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import SnowChat

class AlamofireTestViewController: UIViewController {
    
    @IBOutlet weak var testMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RemoveMe.test()
        RemoveMe.testAsync { msg in
            self.testMessage.text = msg
        }
    }
}
