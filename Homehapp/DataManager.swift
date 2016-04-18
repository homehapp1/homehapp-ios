//
//  DataManager.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/// Notification sent when homes are updated
let homesUpdatedNotification = "homesUpdatedNotification"

/**
Manages the application's persistent storage (Realm.io).

Any (UI) notifications are always sent on the main thread.

Any callback blocks are called on arbitrary threads, not necessarily the main thread.

The methods in this class are re-entrant.
*/
class DataManager {
    private static let singletonInstance = DataManager()
    private let dateFormatter = NSDateFormatter.iso8601ZFormatter()

    // MARK: Private methods

    private func parseVideo(videoJsonObject: AnyObject?) -> Video? {
        if let videoJson = videoJsonObject as? NSDictionary,
            width = videoJson["width"] as? Int,
            height = videoJson["height"] as? Int,
            url = videoJson["url"] as? String {
                let video = Video(url: url, width: width, height: height)
                
                if let thumbnailDataBase64 = videoJson["thumbnail"]?["data"] as? String {
                    video.thumbnailData = NSData(base64EncodedString: thumbnailDataBase64, options: NSDataBase64DecodingOptions())
                }
                
                return video
        }

        return nil
    }

    /**
     Parses JSON for a User and returns the User object if the JSON was valid.
    
    Must be called from within a write transaction.

     - parameter user: if provided, is updated instead of creating a new User object
     - returns: Populated User object
     */
    private func createOrUpdateUserFromJson(json: [String: AnyObject], realm: Realm, user: User? = nil) -> User? {
        assert(realm.inWriteTransaction, "Must be called within Realm write transaction")

        guard let id = json["id"] as? String else {
            log.error("Missing mandatory fields from User JSON, skipping..")
            return nil
        }

        if let userId = json["id"] as? String {
            var user = findUserById(userId)
            
            if user == nil {
                user = User(id: id)
                realm.add(user!, update: true)
            } else {
                // Do not update user from server if server has older information than client
                if let updatedOnServer = json["updatedAt"] as? String,
                    updatedServerDate = dateFormatter.dateFromString(updatedOnServer) {
                    if updatedServerDate < user?.updatedAt {
                        return user
                    } else {
                        user!.updatedAt = NSDate()
                    }
                }
            }
            
            user!.displayName = json["displayName"] as? String
            user!.email = json["email"] as? String
            user!.phoneNumber = json["contact"]?["phone"] as? String
            user!.firstName = json["firstname"] as? String
            user!.lastName = json["lastname"] as? String
            
            if user!.displayName == nil || user!.displayName?.length == 0 {
                if let firstName = json["firstname"] as? String, lastName = json["lastname"] as? String {
                    user!.displayName = "\(firstName) \(lastName)"
                }
            }
            
            user!.facebookUserId = json["fbUserId"] as? String
            if let profileImageJson = json["profileImage"] {
                let profileImage = Image.fromJSON(profileImageJson)
                user!.profileImage = profileImage
            }
            user!.googleUserId = json["googleUserId"] as? String
            
            if let addressJson = json["contact"]?["address"] as? [String: AnyObject] {
                user!.country = addressJson["country"] as? String
                user!.city = addressJson["city"] as? String
                user!.neighbourhood = addressJson["neighbourhood"] as? String
            }
            
            return user
        }
        return nil
    }
    
    /// Parses the story blocks into model objects and adds them to the story object
    private func parseAndAddStoryBlocks(storyObject storyObject: StoryObject, storyBlocksJson: [[String: AnyObject]]) {
        storyBlocksJson.forEach {
            guard let propertiesJson = $0["properties"] as? [String: AnyObject],
                templateString = $0["template"] as? String,
                template = StoryBlock.Template(rawValue: templateString) else {
                    //log.error("StoryBlock object missing mandatory properties: \($0)")
                    return
            }
            
            let storyBlock = StoryBlock(template: template)
            storyBlock.title = propertiesJson["title"] as? String
            storyBlock.mainText = propertiesJson["description"] as? String
            storyBlock.imageAlign = propertiesJson["imageAlign"] as? String
            storyBlock.image = Image.fromJSON(propertiesJson["image"])
            storyBlock.video = parseVideo(propertiesJson["video"])
            
            if let layout = propertiesJson["layout"] as? String {
                storyBlock.layoutRaw = layout
            }
            
            if let content = propertiesJson["content"] as? String where template == .ContentBlock {
                storyBlock.mainText = content
            }
            
            if let images = propertiesJson["images"] as? [[String: AnyObject]] {
                if images.count > 0 {
                    for imageJson in images {
                        if let image = Image.fromJSON(imageJson) {
                            storyBlock.galleryImages.append(image)
                        }
                    }
                } else {
                    // We do not want to append gallery with no images. It is invalid data; skip adding this Gallery block.
                    log.error("Met Gallery block without images - skipping it")
                    return
                }
            }
            
            storyObject.storyBlocks.append(storyBlock)
        }
    }
    
    private func createHomeFromJson(json: [String: AnyObject], realm: Realm) -> Home? {
        assert(realm.inWriteTransaction, "Must be called within Realm write transaction")

        // Check for the presence of all mandatory params
        guard let id = json["id"] as? String,
            createdByJson = json["createdBy"] as? [String: AnyObject],
            createdAt = json["createdAt"] as? String,
            createdDate = dateFormatter.dateFromString(createdAt),
            updatedAt = json["updatedAt"] as? String,
            updatedDate = dateFormatter.dateFromString(updatedAt),
            title = json["title"] as? String else {
                //log.error("Mandatory fields missing in home json: \(json)")
                return nil
        }

        // Will be either existing home or a new one
        let home: Home

        // (Soft) delete any existing story block / image / video objects
        if let existing = realm.objectForPrimaryKey(Home.self, key: id) {
            home = existing
            existing.storyBlocks.forEach { storyBlock in
                storyBlock.galleryImages.forEach { $0.deleted = true }
                storyBlock.galleryImages.removeAll()
                storyBlock.image?.deleted = true
                storyBlock.video?.deleted = true
                storyBlock.deleted = true
            }

            existing.storyBlocks.removeAll()
            existing.floorPlans.removeAll()
            existing.coverImage?.deleted = true
            existing.image?.deleted = true
            existing.agent?.deleted = true
        } else {
            var createdBy: User? = nil
            if createdByJson["id"] as? String == appstate.authUserId {
                createdBy = dataManager.findCurrentUser()
            }
            if createdBy == nil || createdByJson["id"] as? String != appstate.authUserId {
                createdBy = createOrUpdateUserFromJson(createdByJson, realm: realm)
            }
            home = Home(id: id, createdBy: createdBy!, createdAt: createdDate, updatedAt: updatedDate, title: title)
        }

        home.coverImage = Image.fromJSON(json["mainImage"])
        home.image = Image.fromJSON(json["image"]) // home cover image
        home.announcementType = (json["announcementType"] as? String) ?? ""
        home.homeDescription = (json["description"] as? String) ?? ""
        home.slug = (json["slug"] as? String) ?? ""
        home.title = title // Change title for existing home if changed by user
        
        // Home images
        if let homeImages = json["images"] as? NSArray {
            for homeImageJSON in homeImages {
                if let homeImage = Image.fromJSON(homeImageJSON) {
                    home.images.append(homeImage)
                }
            }
        }
        
        // Costs if home for sale or for let
        if let costsJson = json["costs"] as? NSDictionary {
            home.currency = (costsJson["currency"] as? String) ?? ""
            if let sellingPrice = costsJson["sellingPrice"] as? Int {
                home.price = sellingPrice
            } else if let rentalPrice = costsJson["rentalPrice"] as? Int {
                home.price = rentalPrice
            }
        }
        
        // Location and place information
        if let locationJson = json["location"] as? NSDictionary {
            if let addressJson = locationJson["address"] as? NSDictionary {
                home.addressApartment = (addressJson["apartment"] as? String) ?? ""
                home.addressCity = (addressJson["city"] as? String) ?? ""
                home.addressCountry = (addressJson["country"] as? String) ?? ""
                home.addressStreet = (addressJson["street"] as? String) ?? ""
                home.addressZipcode = (addressJson["zipcode"] as? String) ?? ""
            }

            if let coordinatesArray = locationJson["coordinates"] as? NSArray where coordinatesArray.count == 2 {
                home.locationLatitude = (coordinatesArray[0] as? Double) ?? 0.0
                home.locationLongitude = (coordinatesArray[1] as? Double) ?? 0.0
            }
            
            if let neighborhoodJson = locationJson["neighborhood"] as? NSDictionary,
                neighborhoodId = neighborhoodJson["id"] as? String {
                    if let neighborhood = realm.objectForPrimaryKey(Neighborhood.self, key: neighborhoodId) {
                        home.neighborhood = neighborhood
                    }
            }
        }
        
        // Estate agents assigned to home
        if let agentsJson = json["agents"] as? [NSDictionary] where agentsJson.count > 0 {
            if let agentId = agentsJson[0]["id"] {
                if let agent = realm.objectForPrimaryKey(Agent.self, key: agentId) {
                    home.agent = agent
                }
            }
        }

        // Neighbourhood story
        if let userNeighborhoodJson = json["myNeighborhood"] as? [String: AnyObject],
            neighborhoodId = userNeighborhoodJson["id"] as? String {
                if let neighborhood = realm.objectForPrimaryKey(Neighborhood.self, key: neighborhoodId) {
                    home.userNeighborhood = neighborhood
                }
        }
        
        // Story blocks
        if let storyJson = json["story"] as? [String: AnyObject],
            blocksJson = storyJson["blocks"] as? [[String: AnyObject]] {
                parseAndAddStoryBlocks(storyObject: home, storyBlocksJson: blocksJson)
        }
        
        // Likes
        if let likes = json["likes"] {
            home.likes = likes["total"] as! Int
            if let usersWhoHaveLiked = likes["users"] as? [String] {
                if let currentUserId = appstate.authUserId {
                    if usersWhoHaveLiked.contains(currentUserId) {
                        home.iHaveLiked = true
                    }
                }
            }
        }
        
        // Amenities a.k.a features
        if let amenities = json["amenities"] as? NSArray where amenities.count > 0 {
            home.setFeatures(amenities)
        }
        
        // Rooms
        if let rooms = json["rooms"] as? NSDictionary {
            if let bedrooms = rooms["bedrooms"] as? Int {
                home.bedrooms = bedrooms
            }
            if let bathrooms = rooms["bathrooms"] as? Int {
                home.bathrooms = bathrooms
            }
            if let otherRooms = rooms["otherRooms"] as? Int {
                home.otherRooms = otherRooms
            }
        }
        
        // EPCs
        home.epc = Image.fromJSON(json["epc"])

        // FloorPlans
        if let floorPlans = json["floorplans"] as? NSArray {
            for floorPlanJSON in floorPlans {
                if let floorPlan = Image.fromJSON(floorPlanJSON) {
                    home.floorPlans.append(floorPlan)
                }
            }
        }
        
        return home
    }

    // Parse a unique (by id) list of neighborhoods out of the homes list
    private func getUniqueNeighborhoods(homeJsons homeJsons: [[String: AnyObject]]) -> [[String: AnyObject]] {
        var map = [String: [String: AnyObject]]()

        homeJsons.forEach {
            if let neighborhoodJson = $0["location"]?["neighborhood"] as? [String: AnyObject],
                id = neighborhoodJson["id"] as? String {
                    map[id] = neighborhoodJson
            }
            
            if let userNeighborhoodJson = $0["myNeighborhood"] as? [String: AnyObject],
                id = userNeighborhoodJson["id"] as? String {
                    map[id] = userNeighborhoodJson
            }
        }

        return Array(map.values)
    }
    
    private func getUniqueAgents(homes: [NSDictionary]) -> [NSDictionary] {
        var map = [String: NSDictionary]()
        
        for homeJson in homes {
            if let agentsJson = homeJson["agents"] as? [NSDictionary] where agentsJson.count > 0 {
                for agentJson in agentsJson {
                    if let id = agentJson["id"] as? String {
                        map[id] = agentJson
                    }
                }
            }
        }
        
        return Array(map.values)
    }

    /// Must be called from within realm's write transaction
    private func storeNeighborhoods(realm realm: Realm, neighborhoods: NSArray) {
        assert(realm.inWriteTransaction, "Must have write transaction")

        for json in neighborhoods {
            guard let id = json["id"] as? String,
                createdAt = json["createdAt"] as? String,
                createdDate = dateFormatter.dateFromString(createdAt),
                updatedAt = json["updatedAt"] as? String,
                updatedDate = dateFormatter.dateFromString(updatedAt),
                title = json["title"] as? String,
                mainImage = json["mainImage"] as? NSDictionary else {
                    // One of the mandatory fields missing
                    //log.debug("Neighborhood missing mandatory properties: \(json)")
                    continue
            }

            /// Find existing neighborhood or allocate new one if not found
            let neighborhood = { (Void) -> Neighborhood in
                let neighborhood = self.performQueryInRealm { realm in
                    return realm.objectForPrimaryKey(Neighborhood.self, key: id)
                }
                
                return neighborhood ?? Neighborhood(id: id, createdAt: createdDate, updatedAt: updatedDate, title: title)
            }()
            
            neighborhood.image = Image.fromJSON(mainImage)
            neighborhood.title = title
            
            // Remove existing story blocks
            neighborhood.storyBlocks.forEach {
                $0.deleted = true
            }
            neighborhood.storyBlocks.removeAll()
            
            if let storyJson = json["story"] as? [String: AnyObject],
                blocksJson = storyJson["blocks"] as? [[String: AnyObject]] {
                    parseAndAddStoryBlocks(storyObject: neighborhood, storyBlocksJson: blocksJson)
            }

            if let desc = json["description"] as? String {
                neighborhood.neighborhoodDescription = desc
            }

            realm.add(neighborhood, update: true)
        }
    }
    
    private func storeAgents(realm realm: Realm, agents: NSArray) {
        assert(realm.inWriteTransaction, "Must have write transaction")
        
        for json in agents {
            guard let id = json["id"] as? String else {
                // Mandatory id is missing
                continue
            }
            
            let agent = Agent(id: id)
            if let firstname = json["firstname"] as? String {
                agent.firstName = firstname
            }
            if let lastname = json["lastname"] as? String {
                agent.lastName = lastname
            }
            if let email = json["email"] as? String {
                agent.email = email
            }
            if let contactNumber = json["contactNumber"] as? String {
                agent.contactNumber = contactNumber
            }
            
            if let profileImageJson = json["mainImage"] {
                let profileImage = Image.fromJSON(profileImageJson)
                agent.profileImage = profileImage
            }
            
            realm.add(agent, update: true)
        }
    }

    /// Removes all previously soft-deleted objects of a single type
    private func removeDeletedOfType<T: Object>(realm: Realm, _ type: T.Type) {
        assert(realm.inWriteTransaction, "Must be called withing Realm write transaction")
        let results = realm.objects(type).filter("deleted = true")
        log.debug("Deleting \(results.count) soft-deleted objects of type \(type)")
        realm.delete(results)
    }

    /// Removes all previously soft-deleted objects
    private func removeDeleted() {
        let start = NSDate()
        performUpdatesInRealm { realm in
            self.removeDeletedOfType(realm, Image.self)
            self.removeDeletedOfType(realm, Video.self)
            self.removeDeletedOfType(realm, StoryBlock.self)
            self.removeDeletedOfType(realm, Neighborhood.self)
            self.removeDeletedOfType(realm, User.self)
            self.removeDeletedOfType(realm, Home.self)
            self.removeDeletedOfType(realm, Agent.self)
        }
        log.debug("Removing soft-deleted objects took \(-start.timeIntervalSinceNow) seconds.")
    }
    
    // MARK: Public methods

    /// Returns a singleton instance.
    class func sharedInstance() -> DataManager {
        return singletonInstance
    }
    
    /// Find home by given id
    func findHomeById(homeId: String) -> Home? {
        do {
            let realm = try Realm()
            let results = realm.objects(Home).filter("id = %@", homeId)
            if results.count > 0 {
                return results.first
            }
        } catch let error {
            log.error("Fetching my home failed: \(error)")
        }
        return nil
    }
    
    /// Find neighbourhood by given id
    func findNeighbourhoodById(neighborhoodId: String) -> Neighborhood? {
        do {
            let realm = try Realm()
            let results = realm.objects(Neighborhood).filter("id = %@", neighborhoodId)
            if results.count > 0 {
                return results.first
            }
        } catch let error {
            log.error("Fetching my home failed: \(error)")
        }
        return nil
    }
    
    /// Store homes based on given json array
    func storeHomes(homes: NSArray) {
        guard let homes = homes as? [[String: AnyObject]] else {
            return
        }

        runInBackground {
            log.debug("Storing \(homes.count) Homes..")

            let startDate = NSDate()
            let agents = self.getUniqueAgents(homes)
            let neighborhoods = self.getUniqueNeighborhoods(homeJsons: homes)

            do {
                let realm = try Realm()
                realm.beginWrite()

                self.storeNeighborhoods(realm: realm, neighborhoods: neighborhoods)
                self.storeAgents(realm: realm, agents: agents)
                
                for homeJson in homes {
                   if let home = self.createHomeFromJson(homeJson, realm: realm) {
                        realm.add(home, update: true)
                    } else {
                        log.error("Failed to parse objects from home json - ignoring this home.")
                    }
                }
                try realm.commitWrite()
                log.debug("Storing Homes took \(-startDate.timeIntervalSinceNow) seconds.")

                runOnMainThread {
                    NSNotificationCenter.defaultCenter().postNotificationName(homesUpdatedNotification, object: self)
                }
            } catch let error {
                log.debug("Failed to write to realm; error: \(error)")
            }
        }
    }

    /// Allows the caller to do a query with the given realm object
    func performQueryInRealm<T>(@noescape queryBlock: ((realm: Realm) -> T?)) -> T? {
        do {
            let realm = try Realm()
            return queryBlock(realm: realm)
        } catch let error {
            log.error("Realm query error: \(error)")
        }
        
        return nil
    }

    /// Allows the caller to do changes to data, within a transaction
    func performUpdates(@noescape updatesBlock: (Void -> Void)) {
        do {
            let realm = try Realm()
            realm.beginWrite()
            updatesBlock()
            try realm.commitWrite()
        } catch let error {
            log.error("Realm write error: \(error)")
        }
    }

    /// Allows the caller to do changes to data and providing a handle to the realm object, within a transaction
    func performUpdatesInRealm(@noescape updatesBlock: ((realm: Realm) -> Void)) {
        do {
            let realm = try Realm()
            realm.beginWrite()
            updatesBlock(realm: realm)
            try realm.commitWrite()
        } catch let error {
            log.error("Realm write error: \(error)")
        }
    }

    /// Lists all stored homes
    func listHomes() throws -> Results<Home> {
        let realm = try Realm()

        if let currentUser = findCurrentUser() {
            return realm.objects(Home).filter("createdBy != %@ AND deleted != true AND (image != nil OR coverImage != nil)", currentUser).sorted("updatedAt", ascending: false)
        } else {
            return realm.objects(Home).filter("deleted != true AND (image != nil OR coverImage != nil)").sorted("updatedAt", ascending: false)
        }
    }

    /// Return home for the current app user
    func findMyHome() -> Home? {
        if let currentUser = findCurrentUser() {
            do {
                let realm = try Realm()
                let results = realm.objects(Home).filter("createdBy = %@", currentUser)
                if results.count > 0 {
                    return results.first
                }
            } catch let error {
                log.error("Fetching my home failed: \(error)")
            }
        }
        
        return nil
    }
    
    /// Return home that has user neighborhood with given id
    func findHomeForUserNeighborhood(neighborhoodId: String) -> Home? {
        do {
            let realm = try Realm()
            let results = realm.objects(Home).filter("userNeighborhood.id = %@", neighborhoodId)
            if results.count > 0 {
                return results.first
            }
        } catch let error {
            log.error("Fetching home for user neighborhood failed: \(error)")
        }
        return nil
    }

    /**
     Update current app user based on given userJSON
     If currentUser cannot be found, one is created based on userJSON
     */
    func updateCurrentUserFromJSON(json: [String: AnyObject]) {
        appstate.authUserId = json["id"] as? String
        let currentUser = findCurrentUser()
        
        performUpdatesInRealm { realm in
            createOrUpdateUserFromJson(json, realm: realm, user: currentUser)
        }
    }

    /** 
     Get current user that is logged in the app. Current user is defined by isCurrentUser flag.
     Return nil if no user is logged in.
     */
    func findCurrentUser() -> User? {
        if let userId = appstate.authUserId {
            return findUserById(userId)
        } else {
            return nil
        }
    }
    
    // Return user by given id or nil if not found
    func findUserById(userId: String) -> User? {
        return performQueryInRealm { realm in
            let results =  realm.objects(User).filter("id == %@ AND deleted != true", userId)
            return results.first
        }
    }

    /// Mark homes as deleted for future deletion
    func softDeleteHomes(homeIds: NSArray) {
        for homeId in homeIds {
            if let home = findHomeById(homeId as! String) {
                log.debug("deleting home with id: \(homeId)")
                performUpdates({
                    home.deleted = true
                })
            }
        }
    }
    
    func softDeleteNeighbourHoods(neighborhoodIds: NSArray) {
        for neighborhoodId in neighborhoodIds {
            if let neighborhood = findNeighbourhoodById(neighborhoodId as! String) {
                log.debug("deleting neighborhood with id: \(neighborhoodId)")
                performUpdates({
                    neighborhood.deleted = true
                })
            }
        }
    }
    
    /**
     Soft-deletes a given StoryBlock. Does not remove it from any references. Must be called from within
     a write transaction.
    */
    func softDeleteStoryBlock(storyBlock: StoryBlock) {
        storyBlock.deleted = true
        storyBlock.image?.deleted = true
        storyBlock.video?.deleted = true

        storyBlock.galleryImages.forEach { $0.deleted = true }
        storyBlock.galleryImages.removeAll()
    }
    
    /// Soft-deletes user's home if any.
    func softDeleteMyHome() {
        if let currentUser = findCurrentUser() {
            performUpdatesInRealm { realm in
                let results = realm.objects(Home).filter("createdBy != %@ AND deleted != true", currentUser.id)
                if let home = results.first {
                    home.deleted = true
                    home.coverImage?.deleted = true
                    home.image?.deleted = true
                    home.createdBy?.deleted = true
                    
                    for storyBlock in home.storyBlocks {
                        self.softDeleteStoryBlock(storyBlock)
                    }
                    
                    runOnMainThread {
                        NSNotificationCenter.defaultCenter().postNotificationName(homesUpdatedNotification, object: self)
                    }
                }
            }
        }
    }
    
    /// List all image that are not yet sent to server
    func listUnsetImages() throws -> Results<Image> {
        let realm = try Realm()
        return realm.objects(Image).filter("local == true AND localUrl != nil")
    }
    
    /// Initializes resources of this class, including Realm
    init() {
        // This is our current schema version. You must increase this when making changes to Realm models.
        let currentSchema : UInt64 = 1
        let config = Realm.Configuration(schemaVersion: currentSchema, migrationBlock: { migration, oldSchemaVersion in
            log.debug("Running realm.io migration; oldSchemaVersion: \(oldSchemaVersion) to current: \(currentSchema)")

            if oldSchemaVersion < 1 {
                // Nothing to do
            }

            // Example:
            //            migration.enumerate(Person.className()) { oldObject, newObject in
            //                // combine name fields into a single field
            //                let firstName = oldObject!["firstName"] as! String
            //                let lastName = oldObject!["lastName"] as! String
            //                newObject!["fullName"] = "\(firstName) \(lastName)"
            //            }

            // Add version migration handlers here
        })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // Perform the migration by creating a default Realm object
        do {
            let _ = try Realm()
        } catch let error {
            log.error("Failed to initialize Realm; error: \(error)")

            // Show an alert to the user
            dispatch_async(dispatch_get_main_queue(), {
                let alert = UIAlertController(title: "Realm.io error", message: "You must reinstall this application.", preferredStyle: UIAlertControllerStyle.Alert)
                let window = UIApplication.sharedApplication().keyWindow!
                window.rootViewController!.presentViewController(alert, animated: false, completion: nil)
            })
        }

        log.debug("Realm initialized and migration(s) done.")

        // Delete any previously soft-deleted objects
        removeDeleted()
    }
    
    /// Delete all objects stored in the Realm database
    func deleteAll() {
        do {
            let realm = try Realm()
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()
            runOnMainThread {
                NSNotificationCenter.defaultCenter().postNotificationName(homesUpdatedNotification, object: self)
            }
        } catch let error {
            log.error("Failed to delete all objects from Realm: \(error)")
        }
    }
}
