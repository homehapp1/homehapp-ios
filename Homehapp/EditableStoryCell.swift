//
//  EditableHomeStoryCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 31/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation

/// Animation duration for switching between edit/normal modes
let toggleEditModeAnimationDuration = 0.2

/// Describes the available text editing modes for home story cells
enum StoryTextEditMode: Int {
    case HeaderOnly = 1
    case BodyTextOnly = 2
    case HeaderAndBodyText = 3
}

/// Describes an editable cell in the home story table view
protocol EditableStoryCell {
    var supportedTextEditModes: [StoryTextEditMode] { get }
    var resizeCallback: (Void -> Void)? { get set }
    var deleteCallback: (Void -> Void)? { get set }
    var updateCallback: (Void -> Void)? { get set }
    var addImagesCallback: (Int? -> Void)? { get set } // Parameter is max number of images to add; nil = unlimited

    func setEditMode(editMode: Bool, animated: Bool)
}

