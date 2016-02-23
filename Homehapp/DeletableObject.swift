//
//  DeletableObject.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 01/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/// Base class for realm objects that can be soft-deleted.
class DeletableObject: Object {
    dynamic var deleted: Bool = false
}
