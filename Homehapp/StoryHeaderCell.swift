//
//  HomeStoryHeaderCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 19/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import QvikNetwork

/**
 'Header' view placed on top of the large cell before any views formed from the story block.
 
 It displays the main image of the home and some additional controls for sharing, likes and comments.
 */
class StoryHeaderCell: UITableViewCell, EditableStoryCell, UITextViewDelegate {
    /// Main home image view. Accessible from outside for transitions.
    @IBOutlet weak var mainImageView: CachedImageView!

    /// Bottom part container view. Accessible from outside for transitions.
    @IBOutlet weak var bottomPartContainerView: UIView!

    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var titleTextView: ExpandingTextView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var createdByLabel: UILabel!
    @IBOutlet private weak var addCoverPhotoLabel: UILabel!
    
    @IBOutlet private weak var bottomPartContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topPartContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleTopMarginConstraint: NSLayoutConstraint!
    
    /// Action to be executed when share button is pressed
    var shareCallback: (Void -> Void)?

    var resizeCallback: (Void -> Void)? 

    var deleteCallback: (Void -> Void)?

    var updateCallback: (Void -> Void)?

    /// Called when cell indicates that an image should be added (or current one replaced)
    var addImagesCallback: (Int? -> Void)?
    
    /// The scrollview this cell is currently a part of
    private var parentScrollView: UIScrollView? = nil
    
    var supportedTextEditModes: [StoryTextEditMode] {
        return [.HeaderOnly]
    }

    var storyObject: StoryObject? = nil {
        didSet {
            if let image = storyObject?.image {
                mainImageView.imageUrl = image.scaledUrl
                mainImageView.thumbnailData = image.thumbnailData
            } else {
                mainImageView.imageUrl = storyObject?.coverImage?.scaledUrl
                mainImageView.thumbnailData = storyObject?.coverImage?.thumbnailData
            }
            
            if mainImageView.image == nil {
                if storyObject is Neighborhood {
                    mainImageView.image = UIImage(named: "neighbourhood_default_background")
                } else {
                    mainImageView.image = UIImage(named: "home_default_background")
                }
            }
            
            if let title = storyObject?.title where title.length > 0 {
                titleTextView.text = title
                titleLabel.text = title.uppercaseString
            } else {
                if storyObject?.createdBy != nil {
                    if let firstName = storyObject!.createdBy!.firstName?.uppercaseString {
                        titleLabel.text =  "\(firstName)\(NSLocalizedString("homestorycell:someones-home", comment: ""))"
                    }
                }
            }
            
            locationLabel.text = appstate.mostRecentlyOpenedHome?.locationWithCity()
            
            if storyObject is Home {
                titleTextView.placeholderText = NSLocalizedString("edithomestory:header-placeholder", comment: "")
            } else {
                titleTextView.placeholderText = NSLocalizedString("editneighborhoodstory:header-placeholder", comment: "")
            }
            
            createdByLabel.text = ""
            if storyObject!.createdBy?.id != appstate.authUserId {
                if let user = storyObject!.createdBy, let fullName = user.fullName() {
                    createdByLabel.text = "\(NSLocalizedString("homestorycell:by", comment: "")) \(fullName)"
                }
            }
        }
    }

    // MARK: Private methods
    
    func tapped() {
        UIApplication.sharedApplication().sendAction("resignFirstResponder", to: nil, from: nil, forEvent: nil)
    }
    
    /// Returns the UITableView this view is part of, if any
    private func getTableView() -> UITableView? {
        var v = self.superview
        
        while v != nil {
            if let tableView = v as? UITableView {
                return tableView
            }
            
            v = v?.superview
        }
        
        return nil
    }
    
    /// Removes the key-value observer for the current scroll view, if any
    private func removeScrollViewObserver() {
        if let scrollView = parentScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            self.parentScrollView = nil
        }
    }
    
    /// Attempts to start listening to scroll events if attached to a scrollview
    private func handleViewHierarchyChange() {
        // End observing on the current scrollView as this may change
        removeScrollViewObserver()
        
        // Find the ancestor scrollView if one is available
        parentScrollView = getTableView()
        
        if let scrollView = parentScrollView {
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
            
            // Update initial transform
            scrollViewDidScroll(scrollView)
        }
    }
    
    // MARK: Public methods

    /// Setup top / bottom container heights so that this cell fills the parent frame entirely
    func setupGeometry(parentSize parentSize: CGSize, bottomContainerAspectRatio: CGFloat, bottomBarHeight: CGFloat, hasLocation: Bool) {
        
        let margin: CGFloat = 20
        
        // Calculate the bottom container size from parent's size & requested aspect ratio
        bottomPartContainerHeightConstraint.constant = max(parentSize.width * bottomContainerAspectRatio + bottomBarHeight - margin, 135)
        
        // Top container height == what ever is left in parent frame
        topPartContainerHeightConstraint.constant = parentSize.height - bottomPartContainerHeightConstraint.constant
        
        // Title top margin constraint depends on if we have location for home of not
        if !hasLocation {
            titleTopMarginConstraint.constant = margin // Move title up if story has no location
        }

    }
    
    /// Adjusts the parallax / zoom-in effect by the scroll amount
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y

        // Parallax effect through translation; also used to keep the zoomed image in place.
        let yOffset = scrollOffset / 2
        let translate = CGAffineTransformMakeTranslation(0, yOffset)
        
        // Clip the cell contents when parallaxing ('scrolling down'), not while zooming in ('pulling down')
        clipsToBounds = (scrollOffset >= 0) ? true : false
        
        // Pull-down Zoom-in effect through scaling
        let scaleFactor = 1.0 + max(0, -scrollOffset / 300)

        let scale = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
        
        mainImageView.transform = CGAffineTransformConcat(translate, scale)
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            locationLabel.hidden = !(allVisible || !editMode)
            
            cameraButton.hidden = !(allVisible || editMode)
            addCoverPhotoLabel.hidden = !(allVisible || editMode)
            titleTextView.hidden = !(allVisible || editMode)
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            titleLabel.alpha = editMode ? 0.0 : 1.0
            locationLabel.alpha = editMode ? 0.0 : 1.0
            
            cameraButton.alpha = editMode ? 1.0 : 0.0
            addCoverPhotoLabel.alpha = editMode ? 1.0 : 0.0
            titleTextView.alpha = editMode ? 1.0 : 0.0
        }

        if !animated {
            setControlVisibility()
            setControlAlphas()
        } else {
            setControlVisibility(allVisible: true)
            
            UIView.animateWithDuration(0.3, animations: {
                setControlAlphas()
                }, completion: { finished in
                    setControlVisibility()                    
            })
        }
    }
    
    func setTextEditMode(mode: StoryTextEditMode) {
        // No implementation; only one mode supported.
    }

    func getTextEditMode() -> StoryTextEditMode {
        return .HeaderAndBodyText
    }
    
    // MARK: From NSKeyValueObserving
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        scrollViewDidScroll(parentScrollView!)
    }
    
    // MARK: IBAction handlers
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        shareCallback?()
    }
    
    @IBAction func selectPictureButtonPressed(sender: UIButton) {
        addImagesCallback?(1)
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        titleTextView.text = titleTextView.text.trim()
        
        if storyObject?.title != titleTextView.text {
            // Save the home title
            dataManager.performUpdates {
                storyObject?.title = titleTextView.text
            }
            
            updateCallback?()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
    // MARK: From UIView
    
    override func didMoveToWindow() {
        handleViewHierarchyChange()
    }
    
    override func didMoveToSuperview() {
        handleViewHierarchyChange()
    }
    
    // MARK: Lifecycle etc
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        mainImageView.fadeInColor = UIColor.whiteColor()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapped")
        addGestureRecognizer(tapRecognizer)
    }
}
