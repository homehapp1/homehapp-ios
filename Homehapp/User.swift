//
//  User.swift
//  Homehapp
//
//  Created by Lari Tuominen on 28.10.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftDate

/**
 Represents an application user.
*/
class User: DeletableObject {
    dynamic var id: String = ""
    dynamic var displayName: String? = nil
    dynamic var email: String? = nil
    dynamic var firstName: String? = nil
    dynamic var lastName: String? = nil
    dynamic var facebookUserId: String? = nil
    dynamic var googleUserId: String? = nil
    dynamic var country: String? = nil
    dynamic var city: String? = nil
    dynamic var neighbourhood: String? = nil
    dynamic var phoneNumber: String? = nil
    dynamic var profileImage: Image? = nil
    
    dynamic var createdAt: NSDate = NSDate(timeIntervalSince1970: 1)
    dynamic var updatedAt: NSDate = NSDate(timeIntervalSince1970: 1)

    convenience init(id: String) {
        self.init()
        
        self.id = id
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
    
    func toJSON() -> [String: AnyObject] {
        var userJson: [String: AnyObject] = ["id": id]
        if let email = email {
            userJson["email"] = email
        }
        if let displayName = displayName {
            userJson["displayName"] = displayName
        }
        if let firstName = firstName {
            userJson["firstName"] = firstName
        }
        if let lastName = lastName {
            userJson["lastName"] = lastName
        }
        if country != nil || city != nil || phoneNumber != nil {
            var contactJson: [String: AnyObject] = [:]
            var addressJson: [String: AnyObject] = [:]
            if let country = country {
                addressJson["country"] = country
            }
            if let city = city {
                addressJson["city"] = city
            }
            if let neighbourhood = neighbourhood {
                addressJson["neighbourhood"] = neighbourhood
            }
            contactJson["address"] = addressJson
            if let phoneNumber = phoneNumber {
                contactJson["phone"] = phoneNumber
            }
            userJson["contact"] = contactJson
        }
        if let profileImage = profileImage {
            userJson["profileImage"] = profileImage.toJSON()
        }
        return ["user": userJson]
    }
    
    func locationString() -> String? {
        if let city = city where city != "" {
            if let neighbourhood = neighbourhood where neighbourhood != "" {
                return "\(neighbourhood), \(city)"
            }
            return city
        } else if let neighbourhood = neighbourhood {
            return neighbourhood
        }
        return nil
    }
    
    func fullName() -> String? {
        if let firstName = firstName {
            if let lastName = lastName {
                return "\(firstName) \(lastName)"
            } else {
                return "\(firstName)"
            }
        }
        return nil
    }
    
    func isMe() -> Bool {
        return id == appstate.authUserId
    }
}