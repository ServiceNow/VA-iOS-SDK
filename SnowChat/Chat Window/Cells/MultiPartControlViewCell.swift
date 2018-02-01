//
//  ConversationMultiPartViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class MultiPartControlViewCell: UITableViewCell {
    
    static let cellIdentifier = "MultiPartControlViewCell"
    
    @IBOutlet private weak var moreButton: UIButton!
    
    func configure(with model: MultiPartControlViewModel) {
        moreButton.setTitle(model.label, for: .normal)
    }
}
