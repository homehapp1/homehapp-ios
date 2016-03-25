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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var editTitleTextView: ExpandingTextView!
    @IBOutlet private weak var mainImageView: CachedImageView!
    
    @IBOutlet private var titleContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var addImageButton: UIButton!
    
    // Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
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
        } else {
             titleContainerViewHeightConstraint.active = true
        }
    }
    
    // MARK: Public methods
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        updateUI(editMode: editMode)
        
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
    
    override func awakeFromNib() {
        super.awakeFromNib()

        editTitleTextView.placeholderText = NSLocalizedString("edithomestory:content:image-title-placeholder", comment: "")
        
        let singleTap = UITapGestureRecognizer(target: self, action:"tapDetected")
        mainImageView.userInteractionEnabled = true
        mainImageView.addGestureRecognizer(singleTap)
        
    }
}
