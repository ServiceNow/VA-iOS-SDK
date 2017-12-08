//
//  SelectableView.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

class SelectableView: UIControl {
    
    let selectionColor = UIColor(red: 72 / 255, green: 159 / 255, blue: 250 / 255, alpha: 1)
    
    @IBOutlet weak var selectionIndicatorView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectionIndicatorView.image = selectedImage
            } else {
                selectionIndicatorView.image = unselectedImage
            }
        }
    }
    
    var unselectedImage: UIImage?
    var selectedImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let indicatorViewWidth = 0.6 * selectionIndicatorView.bounds.height
        unselectedImage = circleImage(withDiamater: indicatorViewWidth, color: UIColor.white, borderWidth: 1, borderColor: selectionColor)
        selectedImage = circleImage(withDiamater: indicatorViewWidth, color: selectionColor)
    }
}
