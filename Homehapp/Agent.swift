//
//  Agent.swift
//  Homehapp
//
//  Created by Lari Tuominen on 2.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import Foundation

/**
 Represent estate agent
 */
class Agent: DeletableObject {
    
    dynamic var id: String = ""
    dynamic var email: String? = nil
    dynamic var contactNumber: String? = nil
    dynamic var firstName: String? = nil
    dynamic var lastName: String? = nil
    dynamic var profileImage: Image? = nil
    
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
    
    func fullName() -> String? {
        if let firstName = firstName {
            if let lastName = lastName {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return nil
    }
    
}