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
    
    /// Action to be executec when add content button is pressed
    var addContentCallback: (AddContentButtonType -> Void)?
    
    var addContentTopButton: QvikButton?

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
    
    func setEditMode(editMode: Bool, animated: Bool) {
        if editMode {
            addAddContentButton(.AddContentButtonTypeTop, animated: animated)
        } else {
            removeAddContentButtons(animated)
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
    
    /// Add content addition button to cell
    private func addAddContentButton(addContentButtonType: AddContentButtonType, animated: Bool) {
        let addContentButton = QvikButton.button(frame: CGRect(x: 0, y: 0, width: addContentButtonSize, height: addContentButtonSize), type: .Custom) { [weak self] in
            self?.addContentCallback?(addContentButtonType)
        }
        
        addContentButton.setImage(UIImage(named: "icon_add_here"), forState: .Normal)
        addContentButton.contentMode = .Center
        addContentButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(addContentButton)
        addContentButton.layer.zPosition = 2
        
        addContentButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Constrain the delete button so that it will stay in the upper right corner of the cell
        var yConstraint: NSLayoutConstraint? = nil
        if addContentButtonType == .AddContentButtonTypeBottom {
            yConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: addContentButtonSize / 2)
        } else {
            yConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: -addContentButtonSize / 2)
        }
        let horizontalConstraint = NSLayoutConstraint(item: addContentButton, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: addContentButtonSize)
        let heightConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: addContentButtonSize)
        
        NSLayoutConstraint.activateConstraints([yConstraint!, horizontalConstraint, widthConstraint, heightConstraint])
        
        self.addContentTopButton = addContentButton
        
        if animated {
            addContentButton.alpha = 0.0
            UIView.animateWithDuration(toggleEditModeAnimationDuration) {
                addContentButton.alpha = 1.0
            }
        }
    }
    
    /// Remove content addition button from cell
    private func removeAddContentButtons(animated: Bool) {
        if animated {
            addContentTopButton?.alpha = 1.0
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                self.addContentTopButton?.alpha = 0.0
                }, completion: { finished in
                    self.addContentTopButton?.removeFromSuperview()
                    self.addContentTopButton = nil
            })
        } else {
            addContentTopButton?.removeFromSuperview()
            addContentTopButton = nil
        }
    }
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        creatorContainerView.backgroundColor = UIColor.lightBackgroundPatternColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        addContentTopButton?.removeFromSuperview()
        addContentTopButton = nil
    }
}
