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

class AMBTestPanelViewController: UIViewController {

    static private var count: Int = 0
    private var chatId = "999"
    
    let user = CBUser(id: "9927", token: "938457hge98", name: "maint", consumerId: consumerId, consumerAccountId: consumerAccountId, password: "maint")
    let vendor = CBVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9", consumerId: consumerId, consumerAccountId: consumerAccountId)
    
    let chatterbox = Chatterbox()
    
    @IBOutlet weak var chatContent: UITextView!
    @IBOutlet weak var startTopicBtn: UIButton!
    
    @IBAction func onInitiateHandshake(_ sender: Any) {
        
        chatterbox.initializeSession(forUser: user, ofVendor: vendor,
                             whenSuccess: { [weak self] (topicChoices) in
                                if let options = topicChoices.data.richControl?.uiMetadata?.inputControls[0].uiMetadata?.options {
                                    self?.appendContent(message: "What would you like to do?")
                                    for option in options {
                                        self?.appendContent(message: option.label)
                                    }
                                    self?.startTopicBtn.isEnabled = true
                                }
                             },
                             whenError: { [weak self] (error) in
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
            for t in topics {
                self.appendContent(message: "Topic: \(t.title) [\(t.name)]")
                topicName = t.name
            }
        })
        
        chatterbox.startTopic(name: topicName ?? "Create Incident") { [weak self] topic in
            if let topic = topic {
                self?.appendContent(message: "Successfully started User Topic \(topic.data.actionMessage.topicName)")
            } else {
                self?.appendContent(message: "Failed to start topic")
            }
        }
    }
    
    private func appendContent(message: String) {
        if let text = chatContent.text {
            chatContent.text = "\(text)\n***** \(AMBTestPanelViewController.count) *****\n\(message)"
        } else {
            chatContent.text = message
        }
        AMBTestPanelViewController.count += 1
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
