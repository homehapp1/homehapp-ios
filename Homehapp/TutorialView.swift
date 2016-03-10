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
    
    /// Button that closes tutorial View
    @IBOutlet private weak var closeButton: UIButton!
    
    /// Title top constraint
    @IBOutlet private var titleTopConstraint: NSLayoutConstraint!
    
    /// Close button bottom constraint
    @IBOutlet private var closeButtonBottomConstraint: NSLayoutConstraint!
    
    /// Animation time to show or hide view
    private let animationTime = 0.4
    
    /// Navigation top bar height
    private let topBarHeight: CGFloat = 65.0
    
    /// Botton bar height
    private let bottomBarHeight: CGFloat = 50.0
    
    /// Original value of title top constraint
    private var originalTitletopConstraint: CGFloat = 0.0
    
    /// Original value of close button bottom constraint
    private var originalCloseButtonBottomConstraint: CGFloat = 0.0
    
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
            
            switch tutorialType {
            case .WelcomeTutorial:
                titleLabel.text = NSLocalizedString("tutorial:home-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:home-label-1", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:home-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_down")
                contentViewTopConstraint.active = false
                contentViewBottomConstraint.active = true
                contentViewBottomConstraint.constant = bottomBarHeight
                dimmerViewBottomConstraint.constant = bottomBarHeight
                closeButtonBottomConstraint.constant = originalCloseButtonBottomConstraint + 10
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
                titleTopConstraint.constant = originalTitletopConstraint + 20
            case .DoneTutorial:
                dimmerViewTopConstraint.constant = topBarHeight
                titleLabel.text = NSLocalizedString("tutorial:done-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:done-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:done-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_topright")
                contentViewTopConstraint.active = true
                contentViewBottomConstraint.active = false
                contentViewTopConstraint.constant = topBarHeight
                titleTopConstraint.constant = originalTitletopConstraint + 20
            case .EditTutorial:
                dimmerViewTopConstraint.constant = topBarHeight
                titleLabel.text = NSLocalizedString("tutorial:edit-title", comment: "")
                descriptionLabel1.text = NSLocalizedString("tutorial:edit-label", comment: "")
                closeButton.setTitle(NSLocalizedString("tutorial:edit-button", comment: ""), forState: .Normal)
                backgroundImageView.image = UIImage(named: "tutorial_bg_bubble_topright")
                contentViewTopConstraint.active = true
                contentViewBottomConstraint.active = false
                contentViewTopConstraint.constant = topBarHeight
                titleTopConstraint.constant = originalTitletopConstraint + 20
            }
            layoutIfNeeded()
        }
    }
    
    /*
    
    "tutorial:home-title" = "HI THERE!";
    "tutorial:home-label-1" = "This is where you can create your home and neighbourhood moments and stories";
    "tutorial:home-label-2" = "Here you can freely express all the unique and lovely aspects of your home";
    "tutorial:home-label-3" = "Showcase your surroundings and highlight the best things in your neighbourhood";
    "tutorial:home-label-4" = "Add all the details about your home including location, floor plan, features, etc.";
    "tutorial:home-button" = "OK!";
    
    */
    
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
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "TutorialView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
    
}
