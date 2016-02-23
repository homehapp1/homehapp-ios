//
//  StoryObject.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 26/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/// Object that contains an (editable) story, ie. Home or Neighborhood.
protocol StoryObject {
    var storyBlocks: List<StoryBlock> { get }
    var localChanges: Bool { get set }
    var image: Image? { get set }
    var coverImage: Image? { get }
    var title: String { get set }
    var createdBy: User? { get set }
}

