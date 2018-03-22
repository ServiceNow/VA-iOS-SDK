//
//  CarouselControlHeaderView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselControlHeaderView: UICollectionReusableView {
    
    static let headerIdentifier = "CarouselControlHeaderViewIdentifier"
    let titleLabel = UILabel()
    let dividerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        setupDivider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                                     titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                                     titleLabel.topAnchor.constraint(equalTo: topAnchor),
                                     titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    private func setupDivider() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        NSLayoutConstraint.activate([dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                                     dividerView.heightAnchor.constraint(equalToConstant: 1)])
        bringSubview(toFront: dividerView)
    }
    
    func configure(with model: CarouselControlViewModel) {
        titleLabel.text = model.label
    }
}
