//
//  TutorialView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 8.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

enum TutorialType: Int {
    case WelcomeTutorial
    case EditTutorial
    case AddCoverPhotoTutorial
    case AddContentTutorial
    case DoneTutorial
}

class TutorialView: UIView {

    /// Black background to dim the view behind
    @IBOutlet private weak var dimmerView: UIView!
    
    /// View where all the content is inside 
    @IBOutlet private weak var contentView: UIView!
    
    /// Dimmer view top constraint
    @IBOutlet private var dimmerViewTopConstraint: NSLayoutConstraint!

    /// Dimmer view bottom constraint
    @IBOutlet private var dimmerViewBottomConstraint: NSLayoutConstraint!
    
    /// Background image (speech bubble)
    @IBOutlet private weak var backgroundImageView: UIImageView!
    
    /// Content view, where all text and image are inside, bottom constraint 
    @IBOutlet private var contentViewBottomConstraint: NSLayoutConstraint!
    
    /// Content view, where all text and image are inside, top constraint
    @IBOutlet private var contentViewTopConstraint: NSLayoutConstraint!
    
    /// Title shown in tutorial
    @IBOutlet private weak var titleLabel: UILabel!
    
    /// First description label
    @IBOutlet private weak var descriptionLabel1: UILabel!

    /// Second description label
    @IBOutlet private weak var descriptionLabel2: UILabel!

    /// Third description label
    @IBOutlet private weak var descriptionLabel3: UILabel!
    
    /// Fourth description label
    @IBOutlet private weak var descriptionLabel4: UILabel!
    
    /// Button that closes tutorial View
    @IBOutlet private weak var closeButton: UIButton!
    
    /// Title top constraint
    @IBOutlet private var titleTopConstraint: NSLayoutConstraint!
    
    /// Close button bottom constraint
    @IBOutlet private var closeButtonBottomConstraint: NSLayoutConstraint!
    
    /// Welcome tutorial extra content view height
    //@IBOutlet private var welcomeContentViewHeightConstraint: NSLayoutConstraint!
    
    /// Welcome tutorial extra content view
    @IBOutlet private var welcomeContentView: UIView!
    
    /// Animation time to show or hide view
    private let animationTime = 0.4
    
    /// Navigation top bar height
    private let topBarHeight: CGFloat = 65.0
    
    /// Botton bar height
    private let bottomBarHeight: CGFloat = 50.0
    
    /// Margin for things
    private let margin: CGFloat = 20.0
    
    /// Original value of title top constraint
    private var originalTitletopConstraint: CGFloat = 0.0
    
    /// Original value of close button bottom constraint
    private var originalCloseButtonBottomConstraint: CGFloat = 0.0
    
    /// Original value of welcome content view height
    private var originalWelcomeContentViewHeight: CGFloat = 0.0
    
    /// Callback called when user presses close button
    var closeCallback: (TutorialType -> Void)?
    
    /// Set tutorial type to configure view and contents to show in it
    private var tutorialType: TutorialType = .WelcomeTutorial {
        didSet {
            
            // Reset things first and then reveal based on tutorial type
            dimmerViewTopConstraint.constant = 0
            dimmerViewBottomConstraint.constant = 0
            contentViewBottomConstraint.constant = 0
            contentViewTopConstraint.constant = 0
            contentViewBottomConstraint.active = false
            contentViewTopConstraint.active = false
            titleTopConstraint.constant = originalTitletopConstraint
            closeButtonBottomConstraint.constant = originalCloseButtonBottomConstraint
            //welcomeContentViewHeightConstraint.constant = margin
            welcomeContentView.alpha = 0.0
            
            switch tutorialType {
            case .WelcomeTutorial:
                titleLabel.text = NSLocalizedString("tutorial:home-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:home-label-1", comment: "")
                descriptionLabel2.text = NSLocalizedString("tutorial:home-label-2", comment: "")
                descriptionLabel3.text = NSLocalizedString("tutorial:home-label-3", comment: "")
                descriptionLabel4.text = NSLocalizedString("tutorial:home-label-4", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:home-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_down")
                contentViewTopConstraint.active = false
                contentViewBottomConstraint.active = true
                contentViewBottomConstraint.constant = bottomBarHeight
                dimmerViewBottomConstraint.constant = bottomBarHeight
                closeButtonBottomConstraint.constant = originalCloseButtonBottomConstraint + 10
                //welcomeContentViewHeightConstraint.constant = originalWelcomeContentViewHeight
                welcomeContentView.alpha = 1.0
            case .AddContentTutorial:
                titleLabel.text = NSLocalizedString("tutorial:content-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:content-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:content-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_down")
                contentViewTopConstraint.active = false
                contentViewBottomConstraint.active = true
                contentViewBottomConstraint.constant = bottomBarHeight
                dimmerViewBottomConstraint.constant = bottomBarHeight
                closeButtonBottomConstraint.constant = originalCloseButtonBottomConstraint + 10
            case .AddCoverPhotoTutorial:
                titleLabel.text = NSLocalizedString("tutorial:cover-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:cover-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:cover-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_up")
                contentViewTopConstraint.active = true
                contentViewBottomConstraint.active = false
                contentViewTopConstraint.constant = self.height / 2 + 10
                titleTopConstraint.constant = originalTitletopConstraint + margin
            case .DoneTutorial:
                dimmerViewTopConstraint.constant = topBarHeight
                titleLabel.text = NSLocalizedString("tutorial:done-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:done-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:done-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_topright")
                contentViewTopConstraint.active = true
                contentViewBottomConstraint.active = false
                contentViewTopConstraint.constant = topBarHeight
                titleTopConstraint.constant = originalTitletopConstraint + margin
            case .EditTutorial:
                
                // Remove welcome contents ..... and 
                // add constraint from descriptionLabel to Button so that bubble height stays correct
                welcomeContentView.removeFromSuperview()
                
                contentView.addConstraint(NSLayoutConstraint(
                    item:descriptionLabel1,
                    attribute:NSLayoutAttribute.BottomMargin,
                    relatedBy:NSLayoutRelation.Equal,
                    toItem:closeButton,
                    attribute:NSLayoutAttribute.Top,
                    multiplier:1,
                    constant:-margin - 5))
                
                
                dimmerViewTopConstraint.constant = topBarHeight
                titleLabel.text = NSLocalizedString("tutorial:edit-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:edit-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:edit-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_topright")
                contentViewTopConstraint.active = true
                contentViewBottomConstraint.active = false
                contentViewTopConstraint.constant = topBarHeight
                titleTopConstraint.constant = originalTitletopConstraint + margin
           
            }
            layoutIfNeeded()
        }
    }
    
    /// Close tutorial if last screen is shown or move to next screen
    @IBAction func closeButtonPressed(sender: UIButton) {
        self.closeCallback?(self.tutorialType)
        if tutorialType != TutorialType.DoneTutorial {
            tutorialType = TutorialType(rawValue: tutorialType.rawValue + 1)!
        } else {
            UIView.animateWithDuration(animationTime, animations: {
                self.alpha = 0
                }, completion: { finished in
                    appstate.tutorialShown = "yes"
                    self.removeFromSuperview()
            })
        }
    }
    

    // Public methods
    
    func show(tutorialType: TutorialType, closeCallback: (TutorialType -> Void)) {
        self.closeCallback = closeCallback
        self.tutorialType = tutorialType
        UIView.animateWithDuration(animationTime, animations: {
            self.alpha = 1.0
            }, completion: { finished in
                
        })
    }
    
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.alpha = 0
        originalTitletopConstraint = titleTopConstraint.constant
        originalCloseButtonBottomConstraint = closeButtonBottomConstraint.constant
        //originalWelcomeContentViewHeight = welcomeContentViewHeightConstraint.constant
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "TutorialView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
    
}
