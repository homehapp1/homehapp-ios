//
//  EditableHomeInfoView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 3.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import Foundation

/// Describes an editable home info cell
protocol EditableHomeInfoView {
    
    func setEditMode(editMode: Bool, animated: Bool)
    
}