//
//  ControlsViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ControlsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ControlDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var controlContainerView: UIView!
    
    private var controls = [ControlType.boolean, ControlType.multiSelect, ControlType.text, ControlType.outputImage, ControlType.typingIndicator]
    
    private var fakeChatViewController: FakeChatViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        setupFakeChatViewController()
    }
    
    private func setupFakeChatViewController() {
        let fakeChatViewController = FakeChatViewController()
        fakeChatViewController.willMove(toParentViewController: self)
        addChildViewController(fakeChatViewController)
        
        let fakeView: UIView = fakeChatViewController.view
        fakeView.translatesAutoresizingMaskIntoConstraints = false
        controlContainerView.addSubview(fakeView)
        NSLayoutConstraint.activate([fakeView.centerXAnchor.constraint(equalTo: controlContainerView.centerXAnchor),
                                     fakeView.centerYAnchor.constraint(equalTo: controlContainerView.centerYAnchor),
                                     fakeView.widthAnchor.constraint(equalTo: controlContainerView.widthAnchor),
                                     fakeView.heightAnchor.constraint(equalTo: controlContainerView.heightAnchor)])
        
        fakeChatViewController.didMove(toParentViewController: self)
        self.fakeChatViewController = fakeChatViewController
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = controls[indexPath.row].description()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controlType = controls[indexPath.row]
        let uiControl: ControlProtocol
        
        switch controlType {
        case .boolean:
            let booleanMessage = BooleanControlMessage(withData: newControlData())
            uiControl = SnowControlUtils.booleanControl(forBooleanMessage: booleanMessage)
        case .multiSelect:
            let items = [PickerItem(label: "Item 1", value: "1"), PickerItem(label: "Item 2", value: "2"), PickerItem(label: "Item 3", value: "3"), PickerItem(label: "Item 4", value: "4")]
            let multiselectModel = MultiSelectControlViewModel(id: "multi_1234", label: "What is your issue?", required: true, direction: .inbound, items: items)
            uiControl = MultiSelectControl(model: multiselectModel)
        case .text:
            let textModel = TextControlViewModel(label: "Text View", value: "Some random text that is longer than one line........", direction: .inbound)
            uiControl = TextControl(model: textModel)
        case .typingIndicator:
            uiControl = TypingIndicatorControl()
        case .outputImage:
            let imageModel = OutputImageViewModel(label: "mark_image", value: URL(fileURLWithPath: "mark.png"), direction: .inbound)
            uiControl = OutputImageControl(model: imageModel)
        case .singleSelect:
            fatalError("Single select not implemented yet")
        case .unknown:
            fatalError("Unknown")
        }
        
        uiControl.delegate = self
        
        // set the controls
        fakeChatViewController?.controls = [uiControl]
    }
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        
        // update boolean control to 2 text controls when selected
        if model.type == .boolean {
            let booleanMessage = BooleanControlMessage(withData: newControlData())
            let textControls = SnowControlUtils.textControls(forBooleanMessage: booleanMessage)
            fakeChatViewController?.controls = textControls
        }
    }
    
    // Copy-pasted from Marc's code - needs to be removed
    
    fileprivate func newControlData() -> RichControlData<ControlWrapper<Bool?, UIMetadata>> {
        return RichControlData<ControlWrapper>(sessionId: "100",
                                              conversationId: nil,
                                              controlData: ControlWrapper(model: ControlModel(type: "Boolean", name: "Boolean"),
                                                                         uiType: "BooleanControl",
                                                                         uiMetadata: UIMetadata(label:"Test",
                                                                                               required: false,
                                                                                               error: nil),
                                                                         value: nil))
    }
    
}
