//
//  ContentStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 18/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

/**
 Displays a title and text block.
 */
class ContentStoryBlockCell: TextContentStoryBlockCell, UITextViewDelegate {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mainTextLabel: UILabel!
    
    @IBOutlet private var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var editTitleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var editTitleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var mainTextBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var editMainTextBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var editTitleTextView: KMPlaceholderTextView!
    @IBOutlet weak var editMainTextView: KMPlaceholderTextView!
    
    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    var editTitleLabelOriginalTopMarginConstraint: CGFloat = 0

    override var supportedTextEditModes: [StoryTextEditMode] {
        return [.HeaderOnly, .BodyTextOnly, .HeaderAndBodyText]
    }

    override var storyBlock: StoryBlock? {
        didSet {
            if let title = storyBlock?.title {
                titleLabel.text = title
                editTitleTextView.text = ""
                editTitleTextView.height = 0
            } else {
                titleLabel.text = ""
                editTitleTextView.text = ""
            }
            
            if let mainText = storyBlock?.mainText {
                mainTextLabel.text = mainText
                editMainTextView.text = ""
                editMainTextView.height = 0
            } else {
                mainTextLabel.text = ""
                editMainTextView.text = ""
            }
            
            editTitleTextView.scrollEnabled = true
            editMainTextView.scrollEnabled = true
            
            // If content block is first cell, it should have minimal top margin
            // Titlelabel has 8px so that textview is a bit more down
            if removeTopMargin && !editMode {
                titleLabelTopConstraint.constant = 8
                editTitleLabelTopConstraint.constant = 0
            } else {
                titleLabelTopConstraint.constant = titleLabelOriginalTopMarginConstraint
                editTitleLabelTopConstraint.constant = editTitleLabelOriginalTopMarginConstraint
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        editTitleTextView.scrollEnabled = !editMode
        editMainTextView.scrollEnabled = !editMode
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            mainTextLabel.hidden = !(allVisible || !editMode)
            editTitleTextView.hidden = !(allVisible || editMode)
            editMainTextView.hidden = !(allVisible || editMode)
        }
        
        editTitleLabelTopConstraint.active = editMode
        editTitleLabelBottomConstraint.active = editMode
        editMainTextBottomConstraint.active = editMode
        titleLabelTopConstraint.active = !editMode
        titleLabelBottomConstraint.active = !editMode
        mainTextBottomConstraint.active = !editMode
        
        if editMode {
            editTitleTextView.text = titleLabel.text
            editMainTextView.text = mainTextLabel.text
            
            updateTextViewContentSizes()
            
            updateBorder(editTitleTextView.bounds)
            updateBorder2(editMainTextView.bounds)
        } else {
            editTitleTextView.text = nil
            editMainTextView.text = nil
        }
       
        if !animated {
            setControlVisibility()
        } else {
            layoutIfNeeded()
            updateBorder(editTitleTextView.bounds)
            updateBorder2(editMainTextView.bounds)
            setControlVisibility()
        }
    }
    
    private func updateTextViewContentSizes() {
        let editTitleTextViewSize = editTitleTextView.sizeThatFits(CGSizeMake(editTitleTextView.width, 10000000))
        editTitleTextView.contentSize = editTitleTextViewSize
        editTitleTextView.frame.size.height = editTitleTextViewSize.height
        
        let editMainTextViewSize = editMainTextView.sizeThatFits(CGSizeMake(editMainTextView.width, 10000000))
        editMainTextView.contentSize = editMainTextViewSize
        editMainTextView.frame.size.height = editMainTextViewSize.height
      
    }
    
    // MARK: From UITextViewDelegate

    func textViewDidEndEditing(textView: UITextView) {
        titleLabel.text = editTitleTextView.text
        mainTextLabel.text = editMainTextView.text
        
        if storyBlock?.title != editTitleTextView.text || storyBlock?.mainText != editMainTextView.text {
            // Save the home title
            dataManager.performUpdates {
                storyBlock?.title = editTitleTextView.text
                storyBlock?.mainText = editMainTextView.text
            }
            
            updateCallback?()
            resizeCallback?()
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        
        let startHeight = textView.frame.size.height
        let calcHeight = textView.sizeThatFits(textView.frame.size).height
        
        if round(startHeight) != round(calcHeight) {
            
            UIView.setAnimationsEnabled(false) // Disable animations
            
            var tableView = self.superview
            while tableView as? UITableView == nil {
                tableView = tableView?.superview
            }
            
            let tv = tableView as! UITableView
            tv.beginUpdates()
            tv.endUpdates()
            
            let textViewFrameInTableView = tv.convertRect(textView.frame, fromView:textView.superview)
            tv.setContentOffset(CGPointMake(0, textViewFrameInTableView.y - tableView!.height + keyboardHeight + calcHeight), animated: false)
            
            updateTextViewContentSizes()
            
            if textView == editTitleTextView {
                updateBorder(editTitleTextView.bounds)
            } else {
                updateBorder2(editMainTextView.bounds)
            }
            
            UIView.setAnimationsEnabled(true)
        }
    }
 
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView == editTitleTextView {
                // "Next" pressed for title text view; move focus to main text view
                editMainTextView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
            return false
        }
        return true
    }
    
    // MARK: Lifecycle etc
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabelOriginalTopMarginConstraint = titleLabelTopConstraint.constant
        editTitleLabelOriginalTopMarginConstraint = editTitleLabelTopConstraint.constant
        
        editTitleTextView.layer.addSublayer(borderLayer)
        editMainTextView.layer.addSublayer(borderLayer2)
        
        updateBorder(editTitleTextView.bounds)
        updateBorder2(editMainTextView.bounds)
    }

}