//
//  TextEditorModeSelectionView.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 31/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/// Displays text editor mode selection controls
class TextEditorModeSelectionView: UIView {
    private let selectionViewHeight: CGFloat = 50
    private let modeButtonHeight = 50
    private let modeButtonWidth = 60
    
    private var heightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?

    var modeSelectedCallback: (StoryTextEditMode -> Void)?
    
    private var modes = [StoryTextEditMode]()
    
    private var buttons = [QvikButton]()
    
    // MARK: Private methods
    
    /// Performs common initialization
    private func commonInit() {
        backgroundColor = UIColor(hexString: "F0F1F1")
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Create a height constraint
        heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: selectionViewHeight)
        heightConstraint!.active = true
    }
    
    private func resetButtonTintColors() {
        for button in self.buttons {
            button.tintColor = UIColor.homehappDarkColor()
        }
    }
    
    // MARK: Public methods
    
    func setModes(modes: [StoryTextEditMode]) {
        
        if buttons.count > 0 {
            return
        }
        
        self.modes = modes.sort { $0.rawValue < $1.rawValue }
        
        // Create the mode button subviews
        for mode in modes {
            let button = QvikButton.button(frame: CGRect(x: 0, y: 0, width: modeButtonWidth, height: modeButtonHeight))
            buttons.append(button)
            button.pressedCallback = { [weak self] in
                self?.modeSelectedCallback?(mode)
                self?.resetButtonTintColors()
                button.tintColor = UIColor.homehappColorActive()
            }
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = UIColor.homehappDarkColor()
            
            switch mode {
            case .HeaderOnly:
                button.setImage(UIImage(named: "icon_header_only"), forState: .Normal)
            case .BodyTextOnly:
                button.setImage(UIImage(named: "icon_bodytext_only"), forState: .Normal)
            case .HeaderAndBodyText:
                button.setImage(UIImage(named: "icon_header_and_bodytext"), forState: .Normal)
            }
            
            addSubview(button)
        }
        
        setNeedsLayout()
    }
    
    func setCurrentMode(currentMode: StoryTextEditMode) {
        resetButtonTintColors()
        var index = 0
        for mode in modes {
            if mode == currentMode {
                buttons[index].tintColor = UIColor.homehappColorActive()
            }
            index += 1
        }
    }
    
    // MARK: From UIView
    
    /// Lay out the mode buttons
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let divider = subviews.count + 1
        let increment = self.width / CGFloat(divider)
        var x = increment
        let y = self.height / 2
        
        for button in subviews {
            button.center = CGPoint(x: x, y: y)
            x += increment
        }
    }
    
    /// Add constraints
    override func didMoveToSuperview() {
        if let bottomConstraint = bottomConstraint {
            bottomConstraint.active = false
        }
        
        if let leftConstraint = leftConstraint {
            leftConstraint.active = false
        }
        
        if let rightConstraint = rightConstraint {
            rightConstraint.active = false
        }
        
        guard let superview = superview else {
            return
        }
        
        // Align bottom to that of the superview
        bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: superview, attribute: .Bottom, multiplier: 1, constant: 0)
        
        // Align left/right to the superview's
        leftConstraint = NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: superview, attribute: .Leading, multiplier: 1, constant: 0)
        rightConstraint = NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: superview, attribute: .Trailing, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint!, leftConstraint!, rightConstraint!])
    }
    
    // MARK: Lifecycle etc.
    
    convenience init() {
        self.init(frame: CGRect())
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    /// Not used, only implemented be
    required init?(coder aDecoder: NSCoder) {
        self.modes = []
        
        super.init(coder: aDecoder)
        
        commonInit()
    }
}

