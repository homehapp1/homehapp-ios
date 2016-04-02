//
//  ContentDescriptionStoryBlockCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class ContentDescriptionStoryBlockCell: TextContentStoryBlockCell, UITextViewDelegate {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionTextView: UITextView!
 
    override var storyBlock: StoryBlock? {
        didSet {
            if let mainText = storyBlock?.mainText {
                descriptionLabel.text = mainText
                descriptionTextView.text = mainText
            } else {
                descriptionLabel.text = ""
                descriptionTextView.text = ""
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            descriptionLabel.hidden = !(allVisible || !editMode)
            descriptionTextView.hidden = !(allVisible || editMode)
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            descriptionLabel.alpha = editMode ? 0.0 : 1.0
            descriptionTextView.alpha = editMode ? 1.0 : 0.0
        }
        
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
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionLabel.text = descriptionTextView.text
        
        if storyBlock?.mainText != descriptionTextView.text {
            // Save the storyBlock main text
            dataManager.performUpdates {
                storyBlock?.mainText = descriptionTextView.text
            }
            
            updateCallback?()
        }
    }
    
    // MARK: UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        
        let startHeight = textView.frame.size.height
        let calcHeight = textView.sizeThatFits(textView.frame.size).height
        
        if startHeight != calcHeight {
            
            UIView.setAnimationsEnabled(false) // Disable animations
            
            var tableView = self.superview
            while tableView as? UITableView == nil {
                tableView = tableView?.superview
            }
            
            let tv = tableView as! UITableView
            tv.beginUpdates()
            tv.endUpdates()
            
            // change contentOffset only if textview is about to go under to keyboard
            //let textViewFrameInWindow = textView.convertRect(textView.bounds, toView: nil)
            // TODO
            
            //if textViewFrameInWindow.y + calcHeight > tv.height - keyboardHeight {
            let textViewFrameInTableView = tv.convertRect(textView.frame, fromView:textView.superview)
            tv.setContentOffset(CGPointMake(0, textViewFrameInTableView.y - tableView!.height + keyboardHeight + calcHeight), animated: false)
            //}
            
            updateBorder(descriptionTextView.bounds)
            
            UIView.setAnimationsEnabled(true)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    // MARK: Lifecycle etc
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //titleTextView.placeholderText = NSLocalizedString("edithomestory:content:title-placeholder", comment: "")
        layer.shouldRasterize = true
        layer.rasterizationScale = 2.0
        
        descriptionTextView.layer.addSublayer(borderLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateBorder(descriptionTextView.bounds)
        //descriptionLabel.preferredMaxLayoutWidth = CGRectGetWidth(200)
    }
    
}