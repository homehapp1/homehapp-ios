//
//  Neighborhood.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 24/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/**
 Represents a neighborhood (area) where homes reside.
*/
class Neighborhood: DeletableObject, StoryObject {
    dynamic var id: String = ""
    dynamic var createdAt: NSDate = NSDate(timeIntervalSince1970: 1)
    dynamic var updatedAt: NSDate = NSDate(timeIntervalSince1970: 1)
    dynamic var createdBy: User? = nil // TODO not yet populated. does it even need to be?
    dynamic var title: String = ""
    dynamic var image: Image? = nil // 'Main' image for the home
    dynamic var neighborhoodDescription: String? = nil
    dynamic var localChanges: Bool = false // Whether My Home object has local changes and should be updated to remote

    let storyBlocks = List<StoryBlock>()
    
    // Fake variable to satisfy StoryObject conformance
    var coverImage: Image? {
        return nil
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: String, createdAt: NSDate, updatedAt: NSDate, title: String) {
        self.init()
        
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
    
}
