//
//  UITableViewReorderExtension.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 04/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

import QvikSwift

/// Optional delegate protocol for providing customizations for long press reorder operations
@objc protocol LongPressReorderTableViewDelegate: UITableViewDelegate {
    /**
     Implement this to provide a custom snapshot view of a cell for dragging. Example implementation could be:
     
     ```
     func customSnapshotViewForCell(cell: UITableViewCell) -> UIView {
       let snapshot = cell.snapshot()
       let snapshotView = UIImageView(frame: cell.bounds)
       snapshotView.layer.shadowOffset = CGSize(width: -5, height: 0)
       snapshotView.layer.shadowRadius = 5.0
       // TODO other visual setup
     
       return snapshotView
     }

     ```
     
     - returns: custom snapshot view
     */
    optional func tableView(tableView: UITableView, customSnapshotViewForCell cell: UITableViewCell) -> UIView
    
    /**
     Whether a long press reorder should be started for a given table view at a given index path.
     
     - returns: true if reorder should be started, otherwise false
     */
    optional func tableView(tableView: UITableView, shouldStartLongPressReorderAtIndexPath shouldStartLongPressReorder: NSIndexPath) -> Bool
}

// Object association handles
private var stateAssociationHandle: UInt8 = 0

/// Provides long press initiated drag reordering for a table view
public extension UITableView {
    // Collective state for these operations
    private class LongPressReorderState {
        var allowLongPressReordering = false
        var allowLongPressReorderingWhileActiveFirstResponder = false
        var longPressRecognizer: UILongPressGestureRecognizer? = nil
        var snapshotView: UIView? = nil
        var sourceIndexPath: NSIndexPath? = nil
        var delegateImpl: DelegateImpl?
    }
    
    private class DelegateImpl: NSObject, UIGestureRecognizerDelegate {
        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    
    /// Operation state
    private var state: LongPressReorderState {
        get {
            if let reorderState = objc_getAssociatedObject(self, &stateAssociationHandle) as? LongPressReorderState {
                return reorderState
            } else {
                // State object not set; create one
                let reorderState = LongPressReorderState()
                objc_setAssociatedObject(self, &stateAssociationHandle, reorderState, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                return reorderState
            }
        }
        
        set {
            objc_setAssociatedObject(self, &stateAssociationHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Set to true to allow cell reordering by dragging, initiated with a long press
    public var allowLongPressReordering: Bool {
        get {
            return state.allowLongPressReordering
        }
        
        set {
            state.allowLongPressReordering = newValue
            
            // Remove any existing recognizer
            if let oldRecognizer = state.longPressRecognizer,
                recognizerIndex = gestureRecognizers?.indexOf(oldRecognizer) {
                    gestureRecognizers?.removeAtIndex(recognizerIndex)
            }
            state.longPressRecognizer = nil
            
            if newValue {
                let recognizer = UILongPressGestureRecognizer(target: self, action: "cellReorderLongPressHandler:")
                recognizer.delaysTouchesBegan = true
                recognizer.delaysTouchesEnded = true
                state.delegateImpl = DelegateImpl()
                recognizer.delegate = state.delegateImpl
                addGestureRecognizer(recognizer)
                state.longPressRecognizer = recognizer
            }
        }
    }
    
    /// Set to true to allow reordering while there is an active first responder. The default value is false.
    public var allowLongPressReorderingWhileActiveFirstResponder: Bool {
        get {
            return state.allowLongPressReorderingWhileActiveFirstResponder
        }
        
        set {
            state.allowLongPressReorderingWhileActiveFirstResponder = newValue
        }
    }

    private func snapshotCell(cell: UITableViewCell) -> UIView {
        // If the delegate wants to provide the snapshot with customization, prioritize that
        let reorderDelegate = delegate as? LongPressReorderTableViewDelegate
        if let customSnapshotView = reorderDelegate?.tableView?(self, customSnapshotViewForCell: cell) {
            return customSnapshotView
        }

        // By default, we'll create a snapshot view with a little bit of shadow
        let snapshot = cell.snapshot()
        let snapshotView = UIImageView(frame: cell.bounds)
        snapshotView.image = snapshot
        snapshotView.layer.masksToBounds = true
        snapshotView.layer.cornerRadius = 0.0
        snapshotView.layer.shadowOffset = CGSize(width: -5, height: 0)
        snapshotView.layer.shadowRadius = 5.0
        snapshotView.layer.shadowOpacity = 0.4
        
        return snapshotView
    }
    
    private func shouldStartReorderGesture(indexPath: NSIndexPath) -> Bool {
        
        if dataSource?.tableView(self, numberOfRowsInSection: 0) <= 1 {
            return false
        }
        
        // Check if the row in question can be moved
        if dataSource?.tableView?(self, canMoveRowAtIndexPath: indexPath) != true {
            return false
        }
        
        let reorderDelegate = delegate as? LongPressReorderTableViewDelegate
        if reorderDelegate?.tableView?(self, shouldStartLongPressReorderAtIndexPath: indexPath) == false {
            return false
        }

        if !allowLongPressReorderingWhileActiveFirstResponder {
            if UIResponder.getCurrentFirstResponder() != nil {
                return false
            }
        }
        
        return true
    }
    
    func cellReorderLongPressHandler(recognizer: UIGestureRecognizer) {
        let location = recognizer.locationInView(self)
        guard let indexPath = self.indexPathForRowAtPoint(location) else {
            log.debug("Failed to get index path for location: \(location)")
            return
        }
        
        guard let cell = self.cellForRowAtIndexPath(indexPath) else {
            log.debug("Failed to get cell for index path: \(indexPath)")
            return
        }
        
        let state = self.state
        
        switch recognizer.state {
        case .Began:
            if !shouldStartReorderGesture(indexPath) {
                // Reorder should not start; cancel the gesture
                recognizer.enabled = false
                recognizer.enabled = true
                return
            }
            
            // Start by getting rid of the current first responder
            UIResponder.resignCurrentFirstResponder()
            
            // Store index path of the cell where the drag starts from
            state.sourceIndexPath = indexPath
            
            // Snapshot the cell for animations
            state.snapshotView?.removeFromSuperview()
            state.snapshotView = snapshotCell(cell)
            
            // Add the snapshot as subview for the table view
            state.snapshotView!.center = cell.center
            state.snapshotView!.alpha = 0.0
            self.addSubview(state.snapshotView!)
            
            UIView.animateWithDuration(0.25, animations: {
                // Animate the dragged snapshot view to match the gesture location
                state.snapshotView!.center.y = location.y
                
                // Scale the snapshot up a bit to emphasize it being moved
                state.snapshotView!.transform = CGAffineTransformMakeScale(1.05, 1.05)
                
                // Crossfade the original cell and the dragged snapshot
                state.snapshotView!.alpha = 0.95
                cell.alpha = 0.0
                }, completion: { finished in
                    // If our state is still began / changed, set this cell as hidden
                    if (recognizer.state == .Began) || (recognizer.state == .Changed) {
                        cell.hidden = true
                    }
            })

        case .Changed:
            guard let sourceIndexPath = state.sourceIndexPath else {
                return
            }
            
            state.snapshotView?.center.y = location.y
            if indexPath != sourceIndexPath {
                // Check if the row in question can be moved
                if let canMove = dataSource?.tableView?(self, canMoveRowAtIndexPath: indexPath) where !canMove {
                    return
                }
                
                // Inform the data source to move the row data
                dataSource?.tableView?(self, moveRowAtIndexPath: sourceIndexPath, toIndexPath: indexPath)
                
                // Actually swap the rows
                moveRowAtIndexPath(sourceIndexPath, toIndexPath: indexPath)
                
                // Update the 'source' index path to match the table view's state
                state.sourceIndexPath = indexPath
                
                // Make sure the new 'source' cell is hidden 
                if let sourceCell = self.cellForRowAtIndexPath(indexPath) {
                    sourceCell.hidden = true
                }
            } else {
                // Make sure our cell stays hidden; this might become not hidden if reloaded from nib just now
                cell.hidden = true
            }
            
        case .Cancelled:
            log.debug("Longpress gesture cancelled")
            
        default:
            // Any other state means gesture ended; cleanup
            cell.hidden = false
            cell.alpha = 0.0
            
            // Reverse the original animation
            UIView.animateWithDuration(0.25, animations: {
                // Animate the dragged view to match the cell's frame
                state.snapshotView?.center = cell.center
                state.snapshotView?.transform = CGAffineTransformIdentity
                
                state.snapshotView?.alpha = 0.0
                cell.alpha = 1.0
                }, completion: { finished in
                    state.sourceIndexPath = nil
                    state.snapshotView?.removeFromSuperview()
                    state.snapshotView = nil
            })
        }
    }
}


