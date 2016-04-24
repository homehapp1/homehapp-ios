//
//  BaseStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 18/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 Common base class for all story block cell.
 */
class BaseStoryBlockCell: UITableViewCell, EditableStoryCell {
    private var tapRecognizer: UITapGestureRecognizer?

    var storyBlock: StoryBlock?
    
    var deleteButton: QvikButton?
    
    var addContentTopButton: QvikButton?
    
    var addContentBottomButton: QvikButton?
    
    var resizeCallback: (Void -> Void)? 
    
    var updateCallback: (Void -> Void)?
    
    var addContentCallback: (AddContentButtonType -> Void)?

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
    
    /// Base class implementation manages adding the delete, etc. buttons
    func setEditMode(editMode: Bool, animated: Bool) {
        self.editMode = editMode
        
        if editMode {
            addDeleteButton(animated)
            addAddContentButton(.AddContentButtonTypeBottom, animated: animated)
            addAddContentButton(.AddContentButtonTypeTop, animated: animated)
        } else {
            removeDeleteButton(animated)
            removeAddContentButtons(animated)
        }
    }
    
    /// Add delete button to cell
    private func addDeleteButton(animated: Bool) {
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
            let topConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: deleteButtonTopMargin)
            let rightConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -deleteButtonRightMargin)
            let widthConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: deleteButtonSize)
            let heightConstraint = NSLayoutConstraint(item: deleteButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: deleteButtonSize)
            
            NSLayoutConstraint.activateConstraints([topConstraint, rightConstraint, widthConstraint, heightConstraint])
            
            // Layout once to put the close button already in its proper place
            //layoutIfNeeded()
            
            if animated {
                deleteButton!.alpha = 0.0
                UIView.animateWithDuration(toggleEditModeAnimationDuration) {
                    self.deleteButton!.alpha = 1.0
                }
            }
        }
    }
    
    /// Remove delete button from cell
    private func removeDeleteButton(animated: Bool) {
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
            
        // Layout once to put the add content button already in its proper place
        //layoutIfNeeded()
        
        if addContentButtonType == .AddContentButtonTypeBottom {
            self.addContentBottomButton = addContentButton
        } else {
            self.addContentTopButton = addContentButton
        }
            
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
            addContentBottomButton?.alpha = 1.0
            addContentTopButton?.alpha = 1.0
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                self.addContentBottomButton?.alpha = 0.0
                self.addContentTopButton?.alpha = 0.0
                }, completion: { finished in
                    self.addContentBottomButton?.removeFromSuperview()
                    self.addContentBottomButton = nil
                    self.addContentTopButton?.removeFromSuperview()
                    self.addContentTopButton = nil
            })
        } else {
            addContentBottomButton?.removeFromSuperview()
            addContentBottomButton = nil
            addContentTopButton?.removeFromSuperview()
            addContentTopButton = nil
        }
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
        
        addContentBottomButton?.removeFromSuperview()
        addContentBottomButton = nil
        addContentTopButton?.removeFromSuperview()
        addContentTopButton = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseStoryBlockCell.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseStoryBlockCell.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        selectionStyle = .None
    }
    
}
