//
//  Home.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/// Top level model class, representing a home + its story
class Home: DeletableObject, StoryObject {
    
    // Home 'basic' information
    dynamic var id: String = ""
    dynamic var createdAt: NSDate = NSDate(timeIntervalSince1970: 1)
    dynamic var updatedAt: NSDate = NSDate(timeIntervalSince1970: 1)
    dynamic var createdBy: User? = nil // 'Owner' of the home
    dynamic var title: String = ""
    dynamic var homeDescription: String = ""
    
    // Home image
    dynamic var image: Image? = nil // 'Main' image for the home
    dynamic var coverImage: Image? = nil // 'Virtual' property by backend; a selected 'cover' image for the home
    
    // Home neighborhood
    dynamic var neighborhood: Neighborhood? = nil // This is the 'professional' / 'official' Neighborhood object
    dynamic var userNeighborhood: Neighborhood? = nil // This is the user-created Neighborhood object
    
    // Home meta information
    dynamic var slug: String = ""
    dynamic var localChanges: Bool = false // Whether My Home object has local changes and should be updated to remote
    dynamic var isPublic: Bool = true // Defines if home is visible to other users
    dynamic var announcementType: String = "" // buy, rent, story
    
    // Address and location information
    dynamic var addressStreet: String = ""
    dynamic var addressApartment: String = ""
    dynamic var addressCity: String = ""
    dynamic var addressSublocality: String = "" // neighborhood or area such as Mayfair
    dynamic var addressZipcode: String = ""
    dynamic var addressCountry: String = ""
    dynamic var locationLatitude: Double = 0.0
    dynamic var locationLongitude: Double = 0.0

    // Costs
    dynamic var currency: String? = nil // Enum [USD, EUR, GBP](, default to GBP)
    dynamic var price: Int = 0
    
    // Social media actions
    dynamic var shares: Int = 0
    dynamic var likes: Int = 0
    dynamic var iHaveLiked: Bool = false
    
    // Room counts
    dynamic var bedrooms: Int = 0
    dynamic var bathrooms: Int = 0
    dynamic var otherRooms: Int = 0
    
    // Dictionary of home features per category
    // Stored as NSData since Realm does not support storing primitive arrays yet.
    dynamic var homeFeatures: NSData? = nil
    
    // Agent assigned for this home
    dynamic var agent: Agent? = nil

    // Stories / blocks for home story
    let storyBlocks = List<StoryBlock>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
    
    override static func ignoredProperties() -> [String] {
        return []
    }
    
    convenience init(id: String, createdBy: User, createdAt: NSDate, updatedAt: NSDate, title: String) {
        self.init()
        
        self.id = id
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
    }
    
    func locationWithCity() -> String {
        var locationAndCityText = ""
        
        if addressCity.length > 0 {
            if addressSublocality.length > 0 {
                locationAndCityText = "\(addressSublocality), \(addressCity)"
            } else {
                locationAndCityText = "\(addressCity)"
            }
        }
        
        return locationAndCityText
    }
    
    func isMyHome() -> Bool {
        if createdBy != nil {
            return appstate.authUserId == createdBy?.id
        }
        return false
    }

    func setFeatures(features: NSArray) {
        self.homeFeatures = nil
        if features.count == 0 {
            self.homeFeatures = NSData()
            return
        }
        self.homeFeatures = NSKeyedArchiver.archivedDataWithRootObject(features)
    }
    
    func getFeatures() -> NSArray {
        if self.homeFeatures == nil || self.homeFeatures?.length == 0 {
            return NSArray()
        }
        return NSKeyedUnarchiver.unarchiveObjectWithData(self.homeFeatures!) as! NSArray
    }

    /// Return home's selling or letting price with currency
    func priceWithCurrency() -> String? {
        if announcementType == "buy" {
            if let currency = currency where price > 0 {
                return "\(price) \(currency)"
            }
        } else if announcementType == "rent" {
            if let currency = currency where price > 0 {
                return "\(price) \(currency) / pcm"
            }
        }
        return nil
    }
}
