//
//  NotificationBanner.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/6/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class NotificationBanner: UIView {
    
    @IBOutlet weak var label: UILabel?
    
    public var text = "" {
        didSet {
            label?.text = text
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)

        backgroundColor = UIColor.gray

        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.label = label
    }
}
