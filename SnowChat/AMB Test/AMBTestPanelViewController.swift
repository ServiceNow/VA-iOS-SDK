//
//  AMBTestPanelViewController.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/27/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

let consumerAccountId = UUID().uuidString
let consumerId = "marc.attinasi"

class AMBTestPanelViewController: UIViewController, ChatDataListener {

    func chatterbox(_: Chatterbox, topicStarted topic: StartedUserTopicMessage, forChat chatId: String) {
        appendContent(message: "Successfully started User Topic \(topic.data.actionMessage.topicName)")
    }
    
    func chatterbox(_: Chatterbox, topicFinished topic: TopicFinishedMessage, forChat chatId: String) {
        appendContent(message: "\n\nTopic is OVER! Thanks for playing...")
    }
    
    func chatterbox(_: Chatterbox, booleanDataReceived message: BooleanControlMessage, forChat chatId: String) {
        if message.data.direction == MessageConstants.directionFromServer.rawValue {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nooleanControl received: \(label)")

            presentBooleanAlert(message)
        }
    }
    
    func chatterbox(_: Chatterbox, inputDataReceived message: InputControlMessage, forChat chatId: String) {
        if message.data.direction == MessageConstants.directionFromServer.rawValue {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nInputControl received: \(label)")
            
            presentTextInput(message)
        }
    }
    
    func chatterbox(_: Chatterbox, pickerDataReceived message: PickerControlMessage, forChat chatId: String) {
        if message.data.direction == MessageConstants.directionFromServer.rawValue {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nPickerControl received: \(label)")
            
            presentPickerAlert(message)
        }
    }

    func chatterbox(_: Chatterbox, textDataReceived message: OutputTextMessage, forChat chatId: String) {
        if message.data.direction == MessageConstants.directionFromServer.rawValue {
            let label = message.data.richControl?.value ?? "[missing value]"
            appendContent(message: "\nText Output received: \(label)")
        }
    }

    func presentBooleanAlert(_ message: BooleanControlMessage) {
        let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
        let alertController = UIAlertController(title: "SnowChat", message: label, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction!) in
            self.chatterbox.update(control: message.id, ofType: .boolean, withValue: (Bool(true)))
        }
        alertController.addAction(OKAction)
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { (action:UIAlertAction!) in
            self.chatterbox.update(control: message.id, ofType: .boolean, withValue: (Bool(false)))
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion:nil)
    }
    
    func presentTextInput(_ message: InputControlMessage) {
        let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
        let alert = UIAlertController(title: "SnowChat", message: label, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = "My computer is broken..."
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            if let fields = alert.textFields {
                let textField = fields[0]
                print("User entered: \(textField.text ?? "")")
                self.chatterbox.update(control: message.id, ofType: .input, withValue: textField.text ?? "")
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }

    func presentPickerAlert(_ message: PickerControlMessage) {
        let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
        let alertController = UIAlertController(title: "SnowChat", message: label, preferredStyle: .alert)
        
        // actions
        if let options = message.data.richControl?.uiMetadata?.options {
            for option in options {
                let action = UIAlertAction(title: option.label, style: .default) { (action:UIAlertAction!) in
                    self.chatterbox.update(control: message.id, ofType: .picker, withValue: option.value)
                }
                alertController.addAction(action)
            }
        }
        // Present Dialog message
        self.present(alertController, animated: true, completion:nil)
    }
    
    let user = CBUser(id: "9927", token: "938457hge98", name: "maint", consumerId: consumerId, consumerAccountId: consumerAccountId, password: "maint")
    let vendor = CBVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9", consumerId: consumerId, consumerAccountId: consumerAccountId)
    
    let chatterbox = Chatterbox()
    private var notificationObserver: NSObjectProtocol?
    
    @IBOutlet weak var chatContent: UITextView!
    @IBOutlet weak var startTopicBtn: UIButton!
    
    @IBAction func onInitiateHandshake(_ sender: Any) {
        
        chatterbox.initializeSession(forUser: user, vendor: vendor,
                             success: { [weak self] (topicChoices) in
                                if let options = topicChoices.data.richControl?.uiMetadata?.inputControls[0].uiMetadata?.options {
                                    self?.appendContent(message: "What would you like to do?")
                                    for option in options {
                                        self?.appendContent(message: option.label)
                                    }
                                    self?.startTopicBtn.isEnabled = true
                                }
                             },
                             failure: { [weak self] (error) in
                                if let error = error {
                                    self?.appendContent(message: "Error initializing Chatterbox: \(error)")
                                }
                            })
    }

    @IBAction func onTopicSearchChanged(_ sender: Any) {
        if let field = sender as? UITextField, let val = field.text {
            chatterbox.sessionAPI?.suggestTopics(searchText: val, completionHandler: { (topics) in
                for t in topics {
                    self.appendContent(message: "Topic: \(t.title) [\(t.name)]")
                }
            })
        }
    }

    @IBAction func onStartTopic(_ sender: Any) {
        var topicName: String?
        
        chatterbox.sessionAPI?.allTopics(completionHandler: { (topics) in
            if let t = topics.first {
                self.appendContent(message: "Topic: \(t.title) [\(t.name)]")
                topicName = t.name
            }
        })
        
        do {
            try chatterbox.startTopic(withName: topicName ?? "Create Incident", listener: self)
        } catch let error {
            self.appendContent(message: "Error thrown in startTopic: \(error.localizedDescription)")
        }
    }
    
    private func appendContent(message: String) {
        if let text = chatContent.text {
            chatContent.text = "\(text)\n\(message)"
        } else {
            chatContent.text = message
        }
        chatContent.scrollRangeToVisible(NSRange(location: chatContent.text.lengthOfBytes(using: .utf8) - 1, length: 1))
    }

    // MARK: LIFECYCLE METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
