//
//  ControlsViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ControlsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ControlDelegate, ImageDownloader {

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
            guard let booleanModel = BooleanControlViewModel.chatMessageModel(withMessage: booleanMessage)?.controlModel else {
                fatalError("whoops")
            }
            
            uiControl = BooleanControl(model: booleanModel)
        case .multiSelect:
            let items = [PickerItem(label: "Item 1", value: "1"), PickerItem(label: "Item 2", value: "2"), PickerItem(label: "Item 3", value: "3"), PickerItem(label: "Item 4", value: "4")]
            let multiselectModel = MultiSelectControlViewModel(id: "multi_1234", label: "What is your issue?", required: true, items: items)
            uiControl = MultiSelectControl(model: multiselectModel)
        case .text:
            let textModel = TextControlViewModel(label: "Text View", value: "Some random text that is longer than one line........")
            uiControl = TextControl(model: textModel)
        case .typingIndicator:
            uiControl = TypingIndicatorControl()
        case .outputImage:
            let bundle = Bundle(for: type(of: self))
            guard let filePath = bundle.path(forResource: "mark", ofType: "png") else {
                fatalError("Error getting image path")
            }
            
            let url = URL(fileURLWithPath: filePath)
            let imageModel = OutputImageViewModel(label: "Output Image", value: url)
            let outputImageControl = OutputImageControl(model: imageModel)
            outputImageControl.imageDownloader = self
            uiControl = outputImageControl
        case .singleSelect:
            fatalError("Single select not implemented yet")
        case .unknown:
            fatalError("Unknown")
        }
        
        uiControl.delegate = self
        
        // set the controls
        fakeChatViewController?.controls = [uiControl]
    }
    
    // MARK: - ImageDownloader
    
    func downloadImage(forURL url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let image = UIImage(data: data)
            completion(image, nil)
            
            self?.fakeChatViewController?.tableView.beginUpdates()
            self?.fakeChatViewController?.tableView.endUpdates()
        }
    }
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        // ¯\_(ツ)_/¯
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
