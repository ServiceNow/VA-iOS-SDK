//
//  ControlsViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage
import WebKit

class ControlsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ControlDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var controlContainerView: UIView!
    
    private var controls = [ControlType.boolean, ControlType.multiSelect, ControlType.text, ControlType.outputLink, ControlType.typingIndicator]
    
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
            guard let booleanModel = ChatMessageModel.model(withMessage: booleanMessage)?.controlModel else {
                fatalError("whoops")
            }
            
            uiControl = BooleanControl(model: booleanModel)
        case .multiSelect:
            let items = [PickerItem(label: "Item 1", value: "1"), PickerItem(label: "Item 2", value: "2"), PickerItem(label: "Item 3", value: "3"), PickerItem(label: "Item 4", value: "4")]
            let multiselectModel = MultiSelectControlViewModel(id: "multi_1234", label: "What is your issue?", required: true, items: items)
            uiControl = MultiSelectControl(model: multiselectModel)
        case .text:
            let textModel = TextControlViewModel(id: "Text View", value: "Some random text that is longer than one line........")
            uiControl = TextControl(model: textModel)
        case .typingIndicator:
            uiControl = TypingIndicatorControl()
        case .outputImage:
            // swiftlint:disable:next force_unwrapping
            let url = URL(string: "https://i.ytimg.com/vi/uXF9MqdKlTM/maxresdefault.jpg")!
            let imageModel = OutputImageViewModel(id: "image_output_blah_blah_blah", value: url)
            let outputImageControl = OutputImageControl(model: imageModel, imageDownloader: ImageDownloader())
            uiControl = outputImageControl
        case .outputLink:
            guard let url = URL(string: "https://i.ytimg.com/vi/uXF9MqdKlTM/maxresdefault.jpg") else {
                fatalError()
            }
            
            let linkModel = OutputLinkControlViewModel(id: "image_output_blah_blah_blah", value: url)
            let outputLinkControl = OutputLinkControl(model: linkModel, resourceProvider: FakeControlResourceProvider())
            uiControl = outputLinkControl
        case .singleSelect:
            fatalError("Single select not implemented yet")
        default:
            fatalError("pfff")
        }
        
        uiControl.delegate = self
        
        // set the controls
        fakeChatViewController?.controls = [uiControl]
    }
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        // ¯\_(ツ)_/¯
    }
    
    func controlDidFinishLoading(_ control: ControlProtocol) {
        // ¯\_(ツ)_/¯
    }
    
    // Copy-pasted from Marc's code - needs to be removed
    
    fileprivate func newControlData() -> RichControlData<ControlWrapper<Bool?, UIMetadata>> {
        return RichControlData<ControlWrapper>(sessionId: "100",
                                              conversationId: nil,
                                              controlData: ControlWrapper(model: ControlModel(type: "Boolean", name: "Boolean"),
                                                                         uiType: "BooleanControl",
                                                                         uiMetadata: UIMetadata(label:"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi eleifend dapibus lacus, faucibus efficitur enim malesuada vel.",
                                                                                               required: false,
                                                                                               error: nil),
                                                                         value: nil, content: nil))
    }
    
}

class FakeControlResourceProvider: ControlWebResourceProvider {
    var webViewConfiguration: WKWebViewConfiguration {
        return WKWebViewConfiguration()
    }
    
    func authorizedRequest(with url: URL) -> URLRequest {
        return URLRequest(url: url)
    }
}
