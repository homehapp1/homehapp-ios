//
//  HomeStoryFooterCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 19/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 'Footer' view displayed after the story blocks in the home story.
 
 Includes details about the neighborhood.
 */
class HomeStoryFooterCell: UITableViewCell {
    @IBOutlet private weak var mainImageView: CachedImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    var home: Home? {
        didSet {
            mainImageView.imageUrl = home?.userNeighborhood?.image?.scaledUrl
            mainImageView.thumbnailData = home?.userNeighborhood?.image?.thumbnailData
            mainImageView.fadeInColor = UIColor.whiteColor()
            titleLabel.text = home?.userNeighborhood?.title
        }
    }

}
