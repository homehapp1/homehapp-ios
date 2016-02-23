//
//  RecentImageCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 02/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

class RecentImageCell: UICollectionViewCell {
    @IBOutlet weak var trailingMargin: NSLayoutConstraint!
    @IBOutlet weak var playIconImageView: UIImageView!

    @IBOutlet private weak var thumbnailImageView: UIImageView!

    var selectedCallback: ((image: UIImage?) -> Void)?
    
    var image: UIImage? {
        get {
            return thumbnailImageView.image
        }
        
        set {
            thumbnailImageView.image = newValue
            
            UIView.animateWithDuration(0.2) {
                self.thumbnailImageView.alpha = 1.0
            }
        }
    }
    
    func imageTapped() {
        selectedCallback?(image: thumbnailImageView.image)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.alpha = 0.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "imageTapped")
        thumbnailImageView!.addGestureRecognizer(tapRecognizer)
    }
}
