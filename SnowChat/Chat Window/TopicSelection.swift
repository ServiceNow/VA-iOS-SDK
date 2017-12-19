//
//  TopicSelection.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class TopicSelectionHandler: AutoCompleteHandler {
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        return topics.count
    }
    
    func heightForHeaderInSection(_ section: Int) -> CGFloat {
        return section == 0 ? TopicSelectionTableCell.headerHeight : 0
    }
    
    func heightForRowAt(_ indexPath: IndexPath) -> CGFloat {
        return TopicSelectionTableCell.cellHeight
    }
    
    func heightForAutoCompletionView() -> CGFloat {
        let cellHeight:CGFloat = TopicSelectionTableCell.cellHeight
        let headerHeight: CGFloat = TopicSelectionTableCell.headerHeight
        return cellHeight * CGFloat(topics.count) + headerHeight
    }
    
    func didChangeAutoCompletionText(withPrefix prefix: String, andWord word: String) {
        if word.count > 2 {
            searchTopics("\(prefix)\(word)")
        }
    }

    func didCommitEditing(_ value: String) {
        // try to search for the string, if nothing comes back, show all topics
        searchTopics(value, allTopicsIfNoMatch: true)
    }

    func didSelectRowAt(_ indexPath: IndexPath) {
        let selectedRow = (indexPath as NSIndexPath).row
        let topicName = topics[selectedRow].name
        do {
            try chatterbox.startTopic(withName: topicName)
        } catch let error {
            Logger.default.logError("Error starting topic: \(error)")
        }
        
        conversationController?.showAutoCompletionView(false)
        conversationController?.textView.text = ""
    }
    
    func viewForHeaderInSection(_ section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        let containerView = UIView()
        containerView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        let headerView = UILabel()
        var title = isAllTopics ?
            NSLocalizedString("All Topics", comment: "Header for all-topics list matches") :
            NSLocalizedString("Matching Topics", comment: "Header for topic list matches")
        
        headerView.text = title
        
        containerView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 5),
                                     headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 5),
                                     headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
                                     headerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5)])
        return containerView
    }
    
    private var topics = [CBTopic]()
    private var isAllTopics = false
    
    private weak var conversationController: ConversationViewController?
    private let chatterbox: Chatterbox
    
    init(withController controller: ConversationViewController, chatterbox: Chatterbox ) {        
        conversationController = controller
        self.chatterbox = chatterbox
        
        conversationController?.autoCompletionView.register(TopicSelectionTableCell.classForCoder(), forCellReuseIdentifier: TopicSelectionTableCell.cellIdentifier)
        
        // make the autocompletion filter include all alphanumeric characters
        
        // swiftlint:disable force_unwrapping
        let upperCase = (0...26).map({ String(UnicodeScalar("A".unicodeScalars.first!.value + $0)!) })
        let lowerCase = (0...26).map({ String(UnicodeScalar("a".unicodeScalars.first!.value + $0)!) })
        // swiftlint:enable force_unwrapping
        conversationController?.registerPrefixes(forAutoCompletion: upperCase + lowerCase)
        
        conversationController?.textView.placeholder = NSLocalizedString("Type your question...", comment: "Placeholder text for input field when user is matching a topic")
        conversationController?.rightButton.setTitle(NSLocalizedString("Search", comment: "Right button title in topic selection"), for: UIControlState())
    }

    func showAllTopics() {
        chatterbox.sessionAPI?.allTopics { topics in
            self.topics = topics
            self.isAllTopics = true
            self.conversationController?.showAutoCompletionView(topics.count > 0)
        }
    }
    
    func searchTopics(_ searchString: String, allTopicsIfNoMatch: Bool = false) {
        chatterbox.sessionAPI?.suggestTopics(searchText: searchString, completionHandler: { topics in
            if topics.count == 0 {
                if allTopicsIfNoMatch {
                    self.showAllTopics()
                } else {
                    self.topics = topics
                    self.conversationController?.showAutoCompletionView(false)
                }
            } else {
                self.topics = topics
                self.isAllTopics = false
                self.conversationController?.showAutoCompletionView(true)
            }
        })
    }
    
    func cellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        if let controller = conversationController {
            let cell = controller.autoCompletionView.dequeueReusableCell(withIdentifier: TopicSelectionTableCell.cellIdentifier) as! TopicSelectionTableCell
            
            let row = (indexPath as NSIndexPath).row
            let text = topics[row].title
            cell.topicLabel?.text = text
            cell.topicLabel?.textColor = UIColor.blue
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

class TopicSelectionTableCell: UITableViewCell {
    
    static let cellIdentifier = "TopicSelectionTableCell"
    static let cellHeight: CGFloat = 50.0
    static let headerHeight: CGFloat = 35.0
    
    @IBOutlet var topicLabel: UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        topicLabel = UILabel()
        
        if let topicLabel = topicLabel {
            topicLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(topicLabel)
            
            NSLayoutConstraint.activate([topicLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                                         topicLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 5),
                                         topicLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                                         topicLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
