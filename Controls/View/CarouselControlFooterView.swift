//
//  CarouselControlFooterView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/21/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselControlFooterView: UICollectionReusableView {
    static let footerIdentifier = "CarouselControlFooterViewIdentifier"
    let selectButton = UIButton()
    let dividerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
        setupDivider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        selectButton.setTitle(NSLocalizedString("Select", comment: "Completed selection action"), for: .normal)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectButton)
        NSLayoutConstraint.activate([selectButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     selectButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     selectButton.topAnchor.constraint(equalTo: topAnchor),
                                     selectButton.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    private func setupDivider() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        NSLayoutConstraint.activate([dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     dividerView.topAnchor.constraint(equalTo: topAnchor),
                                     dividerView.heightAnchor.constraint(equalToConstant: 1)])
        bringSubview(toFront: dividerView)
    }
}
