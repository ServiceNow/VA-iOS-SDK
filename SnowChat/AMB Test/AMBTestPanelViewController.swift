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

func booleanControlFromBooleanViewModel(viewModel: BooleanControlViewModel) -> BooleanControlMessage {
    let controlData = ControlWrapper<Bool?, UIMetadata>(model: nil, uiType: "Boolean", uiMetadata: UIMetadata(), value: viewModel.resultValue)
    let boolData = RichControlData<ControlWrapper<Bool?, UIMetadata>>(sessionId: "", conversationId: "", controlData: controlData)
    return BooleanControlMessage(withData: boolData)
}

class AMBTestPanelViewController: UIViewController, ChatDataListener, ChatEventListener, ControlDelegate {
    func chatterbox(_ chatterbox: Chatterbox, didCompleteBooleanExchange messageExchange: MessageExchange, forChat chatId: String) {
        Logger.default.logDebug("Boolean Message Completed")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompleteInputExchange messageExchange: MessageExchange, forChat chatId: String) {
        Logger.default.logDebug("Input Message Completed")

    }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompletePickerExchange messageExchange: MessageExchange, forChat chatId: String) {
        Logger.default.logDebug("Picker Message Completed")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompleteMultiSelectExchange messageExchange: MessageExchange, forChat chatId: String) {
        Logger.default.logDebug("Picker Message Completed")
    }
    
    // MARK: ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        handleControlMessageResponse(model)
        
        bubbleViewController?.removeCurrentUIControl()
        bubbleViewController?.view.isHidden = true
    }
    
    // MARK: ChatEventListener
    
    func chatterbox(_: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String) {
        appendContent(message: "Successfully started User Topic \(topic.data.actionMessage.topicName): conversationID=\(topic.data.conversationId ?? "nil")")
        
        conversationId = topic.data.actionMessage.vendorTopicId
        // NOTE: why the conversationID is encoded into the vendorTopicId of the StartTopic message is unclear, but it is
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String) {
        appendContent(message: "\n\nTopic is OVER! Thanks for playing...")
    }
    
    // MARK: ChatDataListener
    
    func chatterbox(_: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        if message.data.direction == .fromServer {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nBooleanControl received: \(label)")

            presentBooleanAlert(message)
        }
    }
    
    func chatterbox(_: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        if message.data.direction == .fromServer {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nInputControl received: \(label)")
            
            presentTextInput(message)
        }
    }
    
    func chatterbox(_: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        if message.data.direction == .fromServer {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nPickerControl received: \(label)")
            
            presentPickerAlert(message)
        }
    }
    
    func chatterbox(_: Chatterbox, didReceiveMultiSelectData message: MultiSelectControlMessage, forChat chatId: String) {
        if message.data.direction == .fromServer {
            let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
            appendContent(message: "\nPickerControl received: \(label)")
            
//            presentPickerAlert(message)
        }
    }

    func chatterbox(_: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        if message.data.direction == .fromServer {
            let label = message.data.richControl?.value ?? "[missing value]"
            appendContent(message: "\nText Output received: \(label)")
        }
    }

    // MARK: internal implementation
    
    private func handleControlMessageResponse(_ model: ControlViewModel) {
        if let conversationId = self.conversationId, let pendingControl = chatterbox?.lastPendingControlMessage(forConversation: conversationId) {
            switch model.type {
            case .boolean:
                if let boolViewModel = model as? BooleanControlViewModel, let boolValue = boolViewModel.resultValue, let requestMessage = pendingControl as? BooleanControlMessage {
                    self.chatterbox?.update(control: BooleanControlMessage(withValue: boolValue, fromMessage: requestMessage))
                }
            default:
                Logger.default.logInfo("unhandled control type \(model.type)")
            }
        } else {
            Logger.default.logError("*** Response received with no pending message - inconsistent state! ***")
        }
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
    
    func presentBooleanAlert(_ message: BooleanControlMessage) {
        var uiControl: ControlProtocol
        if let booleanModel = ChatMessageModel.model(withMessage: message)?.controlModel {
            uiControl = BooleanControl(model: booleanModel)
            uiControl.delegate = self
            
            bubbleViewController?.addUIControl(uiControl)
            bubbleViewController?.view.isHidden = false
        } else {
            Logger.default.logFatal("Fatal error: could not create BooleanControlViewModel")
        }
    }
    
    func presentTextInput(_ message: InputControlMessage) {
        let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
        
        if let conversationId = self.conversationId {
            let alert = UIAlertController(title: "SnowChat", message: label, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = "My computer is broken..."
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                if let fields = alert.textFields {
                    let textField = fields[0]
                    print("User entered: \(textField.text ?? "")")
                    
                    if let requestMessage = self.chatterbox?.lastPendingControlMessage(forConversation: conversationId) as? InputControlMessage {
                        self.chatterbox?.update(control: InputControlMessage(withValue: textField.text ?? "", fromMessage: requestMessage))
                    } else {
                        Logger.default.logError("*** TextInput updated with no pending input message - internal inconsistency ***")
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func presentPickerAlert(_ message: PickerControlMessage) {
        let label = message.data.richControl?.uiMetadata?.label ?? "[missing label]"
        
        if let conversationId = self.conversationId {
            let alertController = UIAlertController(title: "SnowChat", message: label, preferredStyle: .alert)
            if let options = message.data.richControl?.uiMetadata?.options {
                for option in options {
                    let action = UIAlertAction(title: option.label, style: .default) { (action:UIAlertAction!) in
                        print("User Selected: \(option.value)")
                        
                        if let requestMessage = self.chatterbox?.lastPendingControlMessage(forConversation: conversationId) as? PickerControlMessage {
                            self.chatterbox?.update(control: PickerControlMessage(withValue: option.value, fromMessage: requestMessage))
                        } else {
                            Logger.default.logError("*** Picker updated with no pending picker message - internal inconsistency ***")
                        }
                    }
                    alertController.addAction(action)
                }
            }
            self.present(alertController, animated: true, completion:nil)
        }
    }
    
    let user = CBUser(id: "9927", token: "938457hge98", username: DebugSettings.shared.username, consumerId: consumerId, consumerAccountId: consumerAccountId, password: DebugSettings.shared.password)
    let vendor = CBVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9", consumerId: consumerId, consumerAccountId: consumerAccountId)
    
    var chatterbox: Chatterbox?
    var conversationId: String?
    
    private var notificationObserver: NSObjectProtocol?
    var bubbleViewController: BubbleViewController?
    
    @IBOutlet weak var chatContent: UITextView!
    @IBOutlet weak var startTopicBtn: UIButton!
    
    @IBAction func onInitiateHandshake(_ sender: Any) {
        chatterbox?.initializeSession(forUser: user, vendor: vendor,
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
            chatterbox?.apiManager.suggestTopics(searchText: val, completionHandler: { (topics) in
                for t in topics {
                    self.appendContent(message: "Topic: \(t.title) [\(t.name)]")
                }
            })
        }
    }

    @IBAction func onStartTopic(_ sender: Any) {
        var topicName: String?
        
        chatterbox?.apiManager.allTopics(completionHandler: { (topics) in
            if let t = topics.first {
                self.appendContent(message: "Topic: \(t.title) [\(t.name)]")
                topicName = t.name
            }
        })
        
        do {
            try chatterbox?.startTopic(withName: topicName ?? "Create Incident")
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
        
        let instance = ServerInstance(instanceURL: DebugSettings.shared.instanceURL)
        
        chatterbox = Chatterbox(instance: instance, dataListener: self, eventListener: self)
        addBubbleViewController()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
