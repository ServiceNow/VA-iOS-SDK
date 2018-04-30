//
//  TopicDividerCell.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class TopicDividerCell: UITableViewCell, Themeable {
    static let cellIdentifier = "StartTopicDividerCell"
    static let dividerHeight: CGFloat = 1
    
    var model: ChatMessageModel?
    let lineView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with model: ChatMessageModel) {
        self.model = model
        applyTheme(model.theme)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.model = nil
    }
    
    // MARK: ControlPresentable
    
    func setupViews() {
        lineView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(lineView)
        NSLayoutConstraint.activate([lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5.0),
                                     lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5.0),
                                     lineView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
                                     lineView.heightAnchor.constraint(equalToConstant: TopicDividerCell.dividerHeight),
                                     contentView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 10.0)])
    }
    
    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        backgroundColor = theme.backgroundColor
        lineView.backgroundColor = theme.separatorColor
    }
}
