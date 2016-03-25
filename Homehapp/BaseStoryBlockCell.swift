//
//  BaseStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 18/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

private let deleteButtonSize : CGFloat = 30
private let deleteButtonMargin : CGFloat = 8

/**
 Common base class for all story block cell.
 */
class BaseStoryBlockCell: UITableViewCell, EditableStoryCell {
    private var tapRecognizer: UITapGestureRecognizer?

    var storyBlock: StoryBlock?
    
    var deleteButton: QvikButton?
    
    var resizeCallback: (Void -> Void)? 
    
    var updateCallback: (Void -> Void)?

    // Base class returns empty set by default. Override in subclasses.
    var supportedTextEditModes: [StoryTextEditMode] {
        return []
    }

    /// Deletion handler
    var deleteCallback: (Void -> Void)?

    /// Called when cell indicates that an image should be added (or current one replaced)
    var addImagesCallback: (Int? -> Void)?

    /// We remove top margin from cells if cell is first cell or 
    /// previous cell had bottom margin
    var removeTopMargin = false
    
    /// Keyboard height, value updated when keyboard appears
    var keyboardHeight: CGFloat = 0.0
    
    private(set) var editMode = false
    
    /// Base class implementation manages adding the delete button.
    func setEditMode(editMode: Bool, animated: Bool) {
        self.editMode = editMode
        
        if editMode {
            deleteButton = QvikButton.button(frame: CGRect(x: 0, y: 0, width: deleteButtonSize, height: deleteButtonSize), type: .Custom) { [weak self] in
                self?.deleteCallback?()
            }
            deleteButton!.setImage(UIImage(named: "icon_delete"), forState: .Normal)
            deleteButton!.contentMode = .Center
            deleteButton!.translatesAutoresizingMaskIntoConstraints = false
            
            if let _ = self as? GalleryStoryBlockCell {
                // do not add cell level delete button to gallery cell 
            } else {
                addSubview(deleteButton!)
                
                deleteButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                
                // Constrain the delete button so that it will stay in the upper right corner of the cell
                let topConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: deleteButtonMargin)
                let rightConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -deleteButtonMargin)
                let widthConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: deleteButtonSize)
                let heightConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: deleteButtonSize)
                
                NSLayoutConstraint.activateConstraints([topConstraint, rightConstraint, widthConstraint, heightConstraint])
                
                // Layout once to put the close button already in its proper place
                layoutIfNeeded()
                
                if animated {
                    deleteButton!.alpha = 0.0
                    UIView.animateWithDuration(toggleEditModeAnimationDuration) {
                        self.deleteButton!.alpha = 1.0
                    }
                }
            }
        } else {
            if animated {
                deleteButton?.alpha = 1.0
                UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                    self.deleteButton?.alpha = 0.0
                    }, completion: { finished in
                        self.deleteButton?.removeFromSuperview()
                        self.deleteButton = nil
                })
            } else {
                self.deleteButton?.removeFromSuperview()
                self.deleteButton = nil
            }
        }
    }

    func setTextEditMode(mode: StoryTextEditMode) {
        // Base class implementation does nothing
    }
    
    func getTextEditMode() -> StoryTextEditMode {
        // Base class implementation does nothing
        return .HeaderAndBodyText
    }
    
    func keyboardWillShow(notification: NSNotification) {
        addGestureRecognizer(tapRecognizer!)
        
        let info  = notification.userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
        
        let rawFrame = value.CGRectValue
        keyboardHeight = rawFrame.height
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let index = gestureRecognizers?.indexOf(tapRecognizer!) {
            gestureRecognizers?.removeAtIndex(index)
        }
    }
    
    func tapped() {
        UIResponder.resignCurrentFirstResponder()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        deleteButton?.removeFromSuperview()
        deleteButton = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "tapped")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)

        clipsToBounds = true
        selectionStyle = .None
    }
    
}
