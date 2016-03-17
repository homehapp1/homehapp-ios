//
//  ContentImageStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 20/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 Used to display 'ContentImage' layout style story block.
 */
class ContentImageStoryBlockCell: BaseStoryBlockCell, UITextViewDelegate {
    let imageMargin: CGFloat = 3.0
   // private let titleMargin: CGFloat = 40
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var editTitleTextView: ExpandingTextView!
    @IBOutlet private weak var mainImageView: CachedImageView!
    
    @IBOutlet private var titleContainerViewHeightConstraint: NSLayoutConstraint!
    
//    @IBOutlet private weak var titleTopMarginConstraint: NSLayoutConstraint!
//    @IBOutlet private weak var titleHeightConstraint: NSLayoutConstraint!
//    @IBOutlet private weak var titleBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var addImageButton: UIButton!
    
    // Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
//    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    
    /// Image selected -callback; can be used to open a full screen view
    var imageSelectedCallback: ((imageIndex: Int, imageView: UIImageView) -> Void)?
    
    override var resizeCallback: (Void -> Void)? {
        didSet {
            editTitleTextView.resizeCallback = resizeCallback
         }
    }

    override var storyBlock: StoryBlock? {
        didSet {
            titleLabel.text = storyBlock?.title?.uppercaseString
            editTitleTextView.text = storyBlock?.title?.uppercaseString

//            updateUI(editMode: false)
//            setNeedsUpdateConstraints()

            mainImageView.imageUrl = storyBlock?.image?.mediumScaledUrl
            mainImageView.thumbnailData = storyBlock?.image?.thumbnailData
            
            if let fadeInColor = storyBlock?.image?.backgroundColor {
                mainImageView.fadeInColor = UIColor(hexString: fadeInColor)
            }
            
            if let image = storyBlock?.image where image.uploadProgress < 1.0 {
                uploadProgressView.progress = image.uploadProgress
                updateProgressBar()
            }
        }
    }
    
    // MARK: Private methods
    
    private func updateProgressBar() {
        if let image = storyBlock?.image where image.uploadProgress < 1.0 {
            uploadProgressView.hidden = false
            uploadProgressView.progress = image.uploadProgress
            runOnMainThreadAfter(delay: 0.3, task: {
                self.updateProgressBar()
            })
        } else {
            uploadProgressView.hidden = true
        }
    }
    
    private func updateUI(editMode editMode: Bool) {
        if (storyBlock?.title?.length > 0) || editMode {
            titleContainerViewHeightConstraint.active = false
//            log.debug("ACTIVE = FALSE")
          //  titleHeightConstraint.constant = 31
            // titleBottomMarginConstraint.constant = titleMargin
//            if removeTopMargin {
//                titleTopMarginConstraint.constant = 0
//            } else {
//                titleTopMarginConstraint.constant = titleMargin
//            }
        } else {
             titleContainerViewHeightConstraint.active = true
//            log.debug("ACTIVE = TRUE")
//            titleHeightConstraint.constant = 0
//            titleBottomMarginConstraint.constant = 0
//            titleTopMarginConstraint.constant = 3
        }
    }
    
    // MARK: Public methods
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        updateUI(editMode: editMode)
//        setNeedsUpdateConstraints()
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            
            editTitleTextView.hidden = !(allVisible || editMode)
            addImageButton.hidden = !editMode
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            titleLabel.alpha = editMode ? 0.0 : 1.0
            
            editTitleTextView.alpha = editMode ? 1.0 : 0.0
            addImageButton.alpha = editMode ? 1.0 : 0.0
        }
        
        editTitleTextView.heightConstraint.active = editMode
        
        if !animated {
            setControlVisibility()
            setControlAlphas()
        } else {
            setControlVisibility(allVisible: true)
            
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                setControlAlphas()
                self.layoutIfNeeded()
                }, completion: { finished in
                    setControlVisibility()
            })
        }
    }
    
    /// Returns true if this galleryBlock has given image
    func hasImage(image: Image) -> Bool {
        return storyBlock?.image == image
    }
    
    /// Return current frame for given image
    func frameForImage(image: Image) -> CGRect {
        if hasImage(image) {
            return mainImageView.frame
        } else {
            return CGRectZero
        }
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        titleLabel.text = editTitleTextView.text.uppercaseString
        
        if storyBlock?.title != editTitleTextView.text {
            dataManager.performUpdates {
                storyBlock?.title = editTitleTextView.text
            }
            
//            setNeedsLayout()
            updateCallback?()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    // MARK: IBAction handlers
    
    @IBAction func addImageButtonPressed(sender: UIButton) {
        addImagesCallback?(1)
    }
    
    /// Open image if tapped when not in edit mode
    func tapDetected() {
        if editTitleTextView.hidden {
            imageSelectedCallback!(imageIndex: 0, imageView: mainImageView)
        }
    }
    
    // MARK: Lifecycle

//    override func prepareForReuse() {
//        super.prepareForReuse()
//        
//        log.debug("\(unsafeAddressOf(self)) - titleContainerViewHeightConstraint.active = \(titleContainerViewHeightConstraint.active)")
//        titleContainerViewHeightConstraint.active = true
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        editTitleTextView.placeholderText = NSLocalizedString("edithomestory:content:image-title-placeholder", comment: "")
//        titleLabelOriginalTopMarginConstraint = titleTopMarginConstraint.constant
        
        let singleTap = UITapGestureRecognizer(target: self, action:"tapDetected")
        mainImageView.userInteractionEnabled = true
        mainImageView.addGestureRecognizer(singleTap)
        
//        titleContainerViewHeightConstraint.active = true
//        log.debug("\(unsafeAddressOf(self)) - CELL LOADED")
    }
}
