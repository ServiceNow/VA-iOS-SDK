//
//  ControlsViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ControlsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var controlContainerView: UIView!
    
    private var controls = [Control.boolean, Control.multiselect, Control.text]
    
    private var bubbleViewController: BubbleViewController?
    
    override func viewDidLoad() {
        addBubbleViewController()
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
    }
    
    private func addBubbleViewController() {
        let bubbleViewController = BubbleViewController()
        bubbleViewController.willMove(toParentViewController: self)
        addChildViewController(bubbleViewController)
        bubbleViewController.didMove(toParentViewController: self)
        
        guard let bubbleView = bubbleViewController.view else {
            fatalError("ooops, where's the Bubble view?!")
        }
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     bubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                     bubbleView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)])
        self.bubbleViewController = bubbleViewController
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = controls[indexPath.row].displayTitle()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controlName = controls[indexPath.row]
        let uiControl: ControlProtocol?
        
        switch controlName {
        case .boolean:
            let booleanModel = BooleanControlViewModel(id: "boolean_1234", title: "Would you like to create incident?")
            uiControl = BooleanPickerControl(model: booleanModel)
        case .multiselect:
            let multiselectModel = MultiselectControlViewModel(id: "boolean_1234", title: "What is your issue?")
            uiControl = MultiselectPickerControl(model: multiselectModel)
        case .text:
            let textModel = TextViewModel(title: "Some random text that is longer than one line........")
            uiControl = TextControl(model: textModel)
        default:
            fatalError("This control doesnt exist!")
        }
        
        guard let selectedControl = uiControl else {
            return
        }
        
        bubbleViewController?.addUIControl(selectedControl)
    }
    
}
