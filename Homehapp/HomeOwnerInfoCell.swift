//
//  HomeOwnerInfoCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 21/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import MessageUI

class HomeOwnerInfoCell: UITableViewCell {
    @IBOutlet private weak var shareContainerView: UIView!
    @IBOutlet private weak var creatorContainerView: UIView!
    
    @IBOutlet private weak var ownerTitleLabel: UILabel!
    @IBOutlet private weak var ownerImageView: CachedImageView!
    @IBOutlet private weak var ownerNameLabel: UILabel!

    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeImageViewActive: UIImageView!

    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    /// Action to be executed when share button is pressed
    var shareCallback: (Void -> Void)?
    
    /// Action to be executed when like button is pressed
    var likeCallback: (Void -> Void)?
    
    /// Action to be executed when email message button is pressed
    var emailPressedCallback: (Void -> Void)?

    var creator: User? {
        didSet {
            if creator?.displayName != nil {
                ownerNameLabel.text = creator?.displayName
                if let profileImage = creator?.profileImage {
                    ownerImageView.imageUrl = profileImage.url
                    ownerImageView.imageFadeInDuration = 0
                } else {
                    ownerImageView.image = UIImage(named: "default_profile_image")
                }
            }
        }
    }
    
    /// If agent is assigned override home owner information
    var agent: Agent? {
        didSet {
            if let name = agent?.fullName() {
                ownerNameLabel.text = name
                if let profileImage = agent?.profileImage {
                    ownerImageView.imageUrl = profileImage.url
                    ownerImageView.imageFadeInDuration = 0
                } else {
                    ownerImageView.image = UIImage(named: "default_profile_image")
                }
                ownerTitleLabel.text = NSLocalizedString("homeownerinfocell:agent-title", comment: "")
                if let _ = agent?.contactNumber {
                    callButton.hidden = false
                    callLabel.hidden = false
                }
                
                if let _ = agent?.email {
                    messageButton.hidden = false
                    messageLabel.hidden = false
                }
            }
        }
    }
    
    var likeCount: Int = 0 {
        didSet {
            if likeCount == 0 {
                likeCountLabel.hidden = true
            } else {
                likeCountLabel.hidden = false
                likeCountLabel.text = "\(likeCount)"
            }
            
            // Enable like button only if user is logged in
            likeButton.enabled = authService.isUserLoggedIn()
        }
    }
    
    var iHaveLiked: Bool = false {
        didSet {
            likeImageView.alpha = iHaveLiked ? 0 : 1
            likeImageViewActive.alpha = iHaveLiked ? 1 : 0
        }
    }

    @IBAction func shareButtonPressed(button: UIButton) {
        shareCallback?()
    }
    
    @IBAction func likeButtonPressed(button: UIButton) {
        likeButton.enabled = false
        iHaveLiked = iHaveLiked ? false : true
        UIView.animateWithDuration(0.15, animations: {
            self.likeImageView.transform = CGAffineTransformMakeScale(1.5, 1.5)
            self.likeImageViewActive.transform = CGAffineTransformMakeScale(1.5, 1.5)
            self.likeImageView.alpha = 0.5
            self.likeImageViewActive.alpha = 0.5
            }, completion: { finished in
                UIView.animateWithDuration(0.15, animations: {
                    self.likeImageView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    self.likeImageViewActive.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    self.likeImageView.alpha = self.iHaveLiked ? 0 : 1
                    self.likeImageViewActive.alpha = self.iHaveLiked ? 1 : 0
                    }, completion: { finished in
                        self.likeButton.enabled = true
                })
        })
        likeCallback?()
    }
    
    @IBAction func messageButtonPressed(sender: UIButton) {
        emailPressedCallback!()
    }
    
    @IBAction func callButtonPressed(sender: UIButton) {
        if let number = agent?.contactNumber {
            if let phoneCallURL: NSURL = NSURL(string:"tel://\(number)") {
                let application: UIApplication = UIApplication.sharedApplication()
                if (application.canOpenURL(phoneCallURL)) {
                    application.openURL(phoneCallURL);
                }
            }
        }
    }
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        creatorContainerView.backgroundColor = UIColor.lightBackgroundPatternColor()
    }
}
