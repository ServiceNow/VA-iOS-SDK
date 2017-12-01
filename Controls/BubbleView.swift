//
//  BubbleView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/29/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class BubbleView: UIView {
    
    var insetConstraints = [NSLayoutConstraint]()
    
    var contentViewInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            updateContentViewConstraints()
        }
    }
    
    var contentView = UIView()
    
    var borderColor: UIColor = UIColor.red
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addShapeLayer()
        setupContentView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.backgroundColor = UIColor.red
        updateContentViewConstraints()
    }
    
    private func updateContentViewConstraints() {
        NSLayoutConstraint.deactivate(insetConstraints)
        insetConstraints.removeAll()
        
        insetConstraints.append(contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10 + contentViewInsets.left))
        insetConstraints.append(contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentViewInsets.right))
        insetConstraints.append(contentView.topAnchor.constraint(equalTo: topAnchor, constant: contentViewInsets.top))
        insetConstraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentViewInsets.bottom))
        NSLayoutConstraint.activate(insetConstraints)
    }
    
    func addShapeLayer() {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = chatBubblePath(forBounds: bounds)
        layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        (layer.mask as? CAShapeLayer)?.path = chatBubblePath(forBounds: bounds)
    }
}
