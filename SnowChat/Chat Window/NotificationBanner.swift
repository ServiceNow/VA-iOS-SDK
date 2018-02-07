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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(inView parent: UIView, withText text: String, atOffset offset: CGFloat) {
        label?.text = text
        parent.addSubview(self)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            topAnchor.constraint(equalTo: parent.topAnchor, constant: offset),
            widthAnchor.constraint(equalTo: parent.widthAnchor),
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func hide() {
        removeFromSuperview()
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
        
        backgroundColor = UIColor.gray
        translatesAutoresizingMaskIntoConstraints = false
    }
}
