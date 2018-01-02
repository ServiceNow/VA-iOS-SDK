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
    
    func heightForAutoCompletionView() -> CGFloat {
        let cellHeight:CGFloat = TopicSelectionTableCell.estimatedCellHeight
        let headerHeight: CGFloat = TopicSelectionTableCell.estimatedHeaderHeight
        return (cellHeight * CGFloat(topics.count)) + headerHeight
    }
    
    func textDidChange(_ text: String) {
        conversationController?.rightButton.isEnabled = isValid(text: text)
        
        if isValid(text: text) {
            searchTopics(text)
        }
    }

    func didChangeAutoCompletionText(withPrefix prefix: String, andWord word: String) {
        // we are handling textDidChange so no need to use the prefix-based method
    }

    func didCommitEditing(_ value: String) {
        // try to search for the string, if nothing comes back, show all topics
        searchTopics(value, forceMenu: true)
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
        let title = isAllTopics ?
            NSLocalizedString("All Topics", comment: "Header for all-topics list matches") :
            topics.count > 0 ? NSLocalizedString("Matching Topics", comment: "Header for topic list matches") :
                               NSLocalizedString("No Matching Topics", comment: "Header for topic list when no matches")
        
        headerView.text = title
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        NSLayoutConstraint.activate([headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                                     headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 10),
                                     headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                                     headerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)])
        return containerView
    }
    
    private var topics = [CBTopic]()
    private var isAllTopics = false
    
    private weak var conversationController: ConversationViewController?
    private let chatterbox: Chatterbox
    
    init(withController controller: ConversationViewController, chatterbox: Chatterbox ) {        
        conversationController = controller
        self.chatterbox = chatterbox
        
        conversationController?.autoCompletionView.register(TopicSelectionTableCell.self, forCellReuseIdentifier: TopicSelectionTableCell.cellIdentifier)
        
        conversationController?.autoCompletionView.estimatedRowHeight = TopicSelectionTableCell.estimatedCellHeight
        conversationController?.autoCompletionView.rowHeight = UITableViewAutomaticDimension
        conversationController?.autoCompletionView.estimatedSectionHeaderHeight = TopicSelectionTableCell.estimatedHeaderHeight
        conversationController?.autoCompletionView.sectionHeaderHeight = UITableViewAutomaticDimension
        
        conversationController?.textView.isTypingSuggestionEnabled = false
        conversationController?.textView.placeholder = NSLocalizedString("Type your question...", comment: "Placeholder text for input field when user is matching a topic")
        conversationController?.rightButton.setTitle(NSLocalizedString("Search", comment: "Right button title in topic selection"), for: UIControlState())
    }

    func showAllTopics() {
        chatterbox.apiManager.allTopics { topics in
            self.topics = topics
            self.isAllTopics = true
            self.conversationController?.showAutoCompletionView(topics.count > 0)
        }
    }
    
    func searchTopics(_ searchString: String, forceMenu: Bool = false) {
        let searchString = searchString.trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
        chatterbox.apiManager.suggestTopics(searchText: searchString, completionHandler: { topics in
            self.isAllTopics = false
            self.topics = topics
            self.conversationController?.showAutoCompletionView(forceMenu || topics.count > 0)
        })
    }
    
    func cellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        guard let controller = conversationController else {
            return UITableViewCell()
        }
        
        let cell = controller.autoCompletionView.dequeueReusableCell(withIdentifier: TopicSelectionTableCell.cellIdentifier) as! TopicSelectionTableCell
        
        let row = indexPath.row
        let text = topics[row].title
        cell.topicLabel?.text = text
        cell.topicLabel?.textColor = UIColor.blue
        
        return cell
    }
    
    private func isValid(text: String) -> Bool {
        return text.count > 2
    }
}

class TopicSelectionTableCell: UITableViewCell {
    
    static let cellIdentifier = "TopicSelectionTableCell"
    static let estimatedCellHeight: CGFloat = 50.0
    static let estimatedHeaderHeight: CGFloat = 35.0
    
    @IBOutlet var topicLabel: UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        topicLabel = UILabel()
        
        if let topicLabel = topicLabel {
            topicLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(topicLabel)
            
            NSLayoutConstraint.activate([topicLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                                         topicLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 10),
                                         topicLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                                         topicLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
