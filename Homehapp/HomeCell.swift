//
//  HomeStoryCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 16/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

private let titleBottomMargin: CGFloat = 8.0
private let shareIconWidth: CGFloat = 20.0

/**
Displays the 'master' home information in a small form.
*/
class HomeCell: UICollectionViewCell {
    static let nib = UINib(nibName: "HomeCell", bundle: nil)

    /// Parallax-enabled view; can be accessed from outside of this class
    @IBOutlet weak var parallaxView: ParallaxView!
    
    /// Main image view of the cell
    @IBOutlet private weak var mainImageView: CachedImageView!
    
    /// Create story container view for placeholder if user's own home story not created yet
    @IBOutlet private weak var createStoryContainerView: UIView!
    
    /// Bottom container including home title etc. Accessible from outside for transition animations. 
    @IBOutlet weak var bottomContainerView: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var createdByLabel: UILabel!
    @IBOutlet private weak var likeIcon: UIImageView!
    @IBOutlet private weak var likeLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    
    var isMyHomeCell: Bool = false
    
    var cellTappedCallback: (Void -> Void)?
    
    var home: Home? {
        didSet {
            updateUI()
        }
    }
    
    class func loadFromNib() -> HomeCell {
        return nib.instantiateWithOwner(nil, options: nil).first as! HomeCell
    }

    // MARK: Private methods
    
    // Cannot be actually declared private since it's a selector
    func cellTapped() {
        cellTappedCallback?()
    }
    
    // MARK: Public methods
    
    /// Updates the cell UI 
    func updateUI() {
        
        // Home can be nil if user is not logged in
        // First cell is create your home cell which has no home
        if home == nil {
            createStoryContainerView.hidden = false
            mainImageView.imageUrl = nil
            mainImageView.thumbnailData = nil
            locationLabel.text = NSLocalizedString("homestorycell:here-you-can-add", comment: "")
            titleLabel.text = NSLocalizedString("homestorycell:your-very-own-home-story", comment: "")
            createdByLabel.text = NSLocalizedString("homestorycell:by-yourself", comment: "")
            likeIcon.hidden = true
            likeLabel.hidden = true
        } else {
            
            createStoryContainerView.hidden = true
            
            if isMyHomeCell {
                if home!.image != nil {
                   // mainImageView.imageUrl = home!.image?.scaledCoverImageUrl
                    mainImageView.imageUrl = home?.image?.smallScaledUrl
                    mainImageView.thumbnailData = home!.image?.thumbnailData
                    if let fadeInColor = home!.image?.backgroundColor {
                        mainImageView.fadeInColor = UIColor(hexString: fadeInColor)
                    }
                } else {
                    createStoryContainerView.hidden = false
                    mainImageView.imageUrl = nil
                    mainImageView.thumbnailData = nil
                }
            } else {
                if home!.image != nil {
                    // Home image url does not contain http and is not a valid url 
                    // if image upload in sending end has failed
                    if home!.image!.url.contains("http") {
                        mainImageView.imageUrl = home!.image!.smallScaledUrl
                        mainImageView.thumbnailData = home!.image!.thumbnailData
                    } else {
                        mainImageView.thumbnailData = nil
                        mainImageView.imageUrl = nil
                        mainImageView.image = UIImage(named: "home_default_background")
                    }
                    
                    if let backgroundColor = home!.image!.backgroundColor {
                        mainImageView.fadeInColor = UIColor(hexString: backgroundColor)
                    }
                } else {
                    mainImageView.imageUrl = home?.coverImage?.smallScaledUrl
                    mainImageView.thumbnailData = home!.coverImage?.thumbnailData
                }
            }
            
            // Home story title
            if home!.title.length > 0 {
                titleLabel.text = home!.title.uppercaseString
            } else {
                if home!.createdBy != nil {
                    if let firstName = home!.createdBy!.firstName?.uppercaseString {
                        titleLabel.text =  "\(firstName)\(NSLocalizedString("homestorycell:someones-home", comment: ""))"
                    }
                }
            }
            
            // Name of the creator
            createdByLabel.text = ""
            if !home!.isMyHome() {
                if let user = home!.createdBy, let fullName = user.fullName() {
                    createdByLabel.text = "\(NSLocalizedString("homestorycell:by", comment: "")) \(fullName)"
                }
            }

            // Location
            locationLabel.text = home!.locationWithCity()
            
            // Likes
            likeLabel.text = "\(home!.likes)"
            if home!.likes > 0 {
                likeLabel.hidden = false
                likeIcon.hidden = false
            } else {
                likeIcon.hidden = true
                likeLabel.hidden = true
            }
            if home!.iHaveLiked {
                likeIcon.image = UIImage(named: "icon_like_full")
            } else {
                likeIcon.image = UIImage(named: "icon_like_empty")
            }
            
            // Price
            if let price = home!.priceWithCurrency() {
                priceLabel.hidden = false
                priceLabel.text = price
            } else {
                priceLabel.hidden = true
            }
        }
    }
    
    // MARK: From UICollectionViewReusableCell
    
    // This is a performance hack; see http://rbnsn.me/posts/2015/10/04/uicollectionviewcell-autolayout-performance/
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    // MARK: Lifecycle etc.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        parallaxView.parallaxScale = 1.05
        parallaxView.accelerometerMagnitude = 0

        let tapHandler = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapHandler)
    }
}
