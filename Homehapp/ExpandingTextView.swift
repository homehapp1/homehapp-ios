//
//  ExpandingTextView.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 23/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 UITextView that expands (vertically) dynamically when text is entered.
*/
@IBDesignable
public class ExpandingTextView: UITextView {
    @IBInspectable
    public var minimumHeight: CGFloat = 0 {
        didSet {
            updateSize()
        }
    }
    
    @IBInspectable
    public var maximumHeight: CGFloat = 0 {
        didSet {
            updateSize()
        }
    }
    
    @IBInspectable
    public var dottedBorderColor: UIColor = UIColor.whiteColor() {
        didSet {
            borderLayer.strokeColor = dottedBorderColor.CGColor
        }
    }
    
    @IBInspectable
    public var placeholderText: String = "" {
        didSet {
            placeholderLabel?.text = placeholderText            
            updatePlaceholder()
        }
    }
    
    /// A flag indicating whether the text view should resize itself
    public var shouldResize = true
    
    /// Callback to be called when the text view has resized itself
    public var resizeCallback: (Void -> Void)?
    
    /// Main height constraint. Accessible from outside of the class.
    public var heightConstraint: NSLayoutConstraint!
    
    private var borderLayer: CAShapeLayer!
    private var placeholderLabel: UILabel?
    
    override public var text: String! {
        didSet {
            updatePlaceholder()
            updateSize(notify: false)
        }
    }

    func editingDidChange(notification: NSNotification) {
        updatePlaceholder()
    }
    
    func textDidChange(notification: NSNotification) {
        updatePlaceholder()
        updateSize()
    }
    
    /// Updates the placeholder text properties
    private func updatePlaceholder() {
        // Hide placeholder if currently editing this text view or it has any text set
        placeholderLabel?.hidden = isFirstResponder() || (text.length > 0)
    }
    
    /// Calculate & update the height for the editor
    public func updateSize(notify notify: Bool = true) {
        if !shouldResize {
            return
        }
        
        let fittingSize = sizeThatFits(CGSize(width: frame.width, height: 9999))
        var newHeight = ceil(fittingSize.height)
        
        if (minimumHeight > 0) && (minimumHeight > newHeight) {
            newHeight = minimumHeight
        }
        
        if (maximumHeight > 0) && (newHeight > maximumHeight) {
            return
        }
        
        if newHeight != heightConstraint.constant {
            heightConstraint.constant = newHeight
            
            if let resizeCallback = resizeCallback where notify {
                resizeCallback()
            }
        }
    }
    
    private func commonInit() {
        scrollEnabled = false
        scrollsToTop = false

        contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        // Add a dotted border
        borderLayer = CAShapeLayer()
        borderLayer.strokeColor = dottedBorderColor.CGColor
        borderLayer.fillColor = nil
        borderLayer.lineDashPattern = [3, 3]
        borderLayer.lineWidth = 1.0
        layer.addSublayer(borderLayer)

        // Find a matching height constraint if any
        for constraint in constraints {
            if let item = constraint.firstItem as? UIView where item == self && constraint.firstAttribute == .Height {
                heightConstraint = constraint
                break
            }
        }
        
        if heightConstraint == nil {
            // Well, we need a height constraint, so lets add one now
            heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 10)
            heightConstraint.priority = 999
            heightConstraint!.active = true
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "editingDidChange:", name: UITextViewTextDidBeginEditingNotification, object: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "editingDidChange:", name: UITextViewTextDidEndEditingNotification, object: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange:", name: UITextViewTextDidChangeNotification,
            object: self)
        
        if placeholderLabel == nil {
            placeholderLabel = UILabel(frame: self.frame)
            placeholderLabel!.font = self.font
            placeholderLabel!.textColor = self.textColor
            placeholderLabel!.alpha = 0.6
            placeholderLabel!.numberOfLines = 0
            placeholderLabel!.textAlignment = self.textAlignment
            placeholderLabel!.text = placeholderText
            
            placeholderLabel!.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(placeholderLabel!)
            
            // Constrain the placeholder label to be centered on this item and not to grow any wider than this
            let xConstraint = NSLayoutConstraint(item: placeholderLabel!, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
            let yConstraint = NSLayoutConstraint(item: placeholderLabel!, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: placeholderLabel!, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: self, attribute: .Width, multiplier: 1, constant: 0)
            
            NSLayoutConstraint.activateConstraints([xConstraint, yConstraint, widthConstraint])
        }

        updatePlaceholder()
        updateSize()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        // Force the text to be shown completely instead of being sometimes "scrolled"
        contentOffset = CGPoint(x: 0, y: 0)
        
        updateSize(notify: false)
        
        borderLayer.path = UIBezierPath(rect: self.bounds).CGPath
        borderLayer.frame = self.bounds
        borderLayer.frame.origin.y = 0
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        commonInit()
    }
}
