//
//  RemoteService.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation

// https://mobile-api.homehapp.com/api-docs/
// homehapp / qvik-homehapp-docs

/// Networking layer against homehapp backend.
class RemoteService: BaseRemoteService {
    private let keychainServiceName = "homehapp"
    
    private let baseUrl = "https://mobile-api.homehapp.com"
//    private let baseUrl = "http://staging-api.homehapp.com:8080"
    
    private static let singletonInstance = RemoteService()
    
    private let dateFormatter = NSDateFormatter.iso8601ZFormatter()

    // MARK: Private methods
    
    /// Create json presentation for home and neighborhood story block
    private func createStoryBlockJSON(storyBlock: StoryBlock) -> [String: AnyObject] {
        var blockProperties = [String: AnyObject]()
        
        switch storyBlock.template {
        case "BigVideo":
            if let videoJson = storyBlock.video?.toJSON() {
                blockProperties["video"] = videoJson
            }
        case "ContentImage":
            if let imageJson = storyBlock.image?.toJSON() {
                blockProperties["image"] = imageJson
            }
        case "ContentBlock":
            if let text = storyBlock.mainText {
                blockProperties["content"] = text
            }
        case "Gallery":
            blockProperties["images"] = storyBlock.galleryImages.flatMap { ($0).toJSON() }
        default:
            log.debug("unknown story block template: \(storyBlock.template)")
        }
        
        blockProperties["layout"] = storyBlock.layoutRaw
        blockProperties["title"] = storyBlock.title
        
        return [
            "template": storyBlock.template,
            "properties": blockProperties
        ]
    }
    
    /// Create json presentation for neighborhood
    private func createNeighborhoodJSON(neighborhood: Neighborhood) -> [String: AnyObject] {
        var json: [String: AnyObject] = [
            "id": neighborhood.id,
            "title": neighborhood.title,
            ]
        
        if let image = neighborhood.image {
            if let imageJson = image.toJSON() {
                json["images"] = [imageJson]
            }
        }
        
        json["story"] = [
            "enabled": true,
            "blocks": neighborhood.storyBlocks.map { createStoryBlockJSON($0) }
        ]

        return ["neighborhood": json]
    }

    /// Create json presentation for home
    private func createHomeJSON(home: Home) -> [String: AnyObject] {
        var homeJson: [String: AnyObject] = [
            "title": home.title,
            "costs": [
                "currency": home.currency ?? "GBP",
                "price" : home.price
            ]
        ]
        
        var locationJson: [String: AnyObject] = [
            "address": [
                "street": home.addressStreet,
                "apartment": home.addressApartment,
                "city": home.addressCity,
                "zipcode": home.addressZipcode,
                "country": home.addressCountry
            ]
        ]

        if (home.locationLatitude > 0.0) || (home.locationLongitude > 0.0) {
            locationJson["coordinates"] = [home.locationLatitude, home.locationLongitude]
        }
        
        homeJson["location"] = locationJson
        
        if let imageJson = home.image?.toJSON() {
            homeJson["image"] = imageJson
        }
        
        // Create home.story structure
        homeJson["story"] = [
            "enabled": true,
            "blocks": home.storyBlocks.map { createStoryBlockJSON($0) }
        ]
        
        homeJson["enabled"] = home.isPublic
        homeJson["description"] = home.homeDescription
        
        // Home rooms
        let roomsJson: [String: Int] = [
            "bedrooms": home.bedrooms,
            "bathrooms": home.bathrooms,
            "otherRooms": home.otherRooms
        ]
        
        homeJson["rooms"] = roomsJson
        
        // Home features
        if home.getFeatures().count > 0 {
            let features = home.getFeatures() as? [String]
            homeJson["amenities"] = features
        }
        
        // EPC
        if home.epc != nil {
            homeJson["epc"] = home.epc!.toJSON()
        }
        
        // Floorplan
        if home.floorPlans.count > 0 {
            var floorPlansJson = [AnyObject]()
            for floorPlan in home.floorPlans {
                if let floorPlanJson = floorPlan.toJSON() {
                    floorPlansJson.append(floorPlanJson)
                }
            }
            homeJson["floorplans"] = floorPlansJson
        }
        
        return ["home": homeJson]
    }
    
    /// /// Fetch homes that are deleted after timestamp homesLastDeleted in appstate
    private func fetchDeletedHomes() {
        let sentTime = NSDate()
        if let lastUpdated = appstate.homesLastDeleted {
            let lastUpdatedString = dateFormatter.stringFromDate(lastUpdated)
            let url = "\(baseUrl)/api/deleted/home?since=\(lastUpdatedString)"
            request(.GET, url, parameters: nil, encoding: .URL, headers: nil) { response in
                if response.success {
                    appstate.homesLastDeleted = sentTime
                    if let json = response.parsedJson, items = json["items"] as? NSArray where items.count > 0 {
                        dataManager.softDeleteHomes(items)
                    }
                }
            }
        }
    }
    
    /// Fetch neighborhoods that are deleted after timestamp neighborhoodsLastDeleted in appstate
    private func fetchDeletedNeighbourHoods() {
        let sentTime = NSDate()
        if let lastUpdated = appstate.neighborhoodsLastDeleted {
            let lastUpdatedString = dateFormatter.stringFromDate(lastUpdated)
            let url = "\(baseUrl)/api/deleted/neighborhood?since=\(lastUpdatedString)"
            request(.GET, url, parameters: nil, encoding: .URL, headers: nil) { response in
                if response.success {
                    appstate.neighborhoodsLastDeleted = sentTime
                    if let json = response.parsedJson, items = json["items"] as? NSArray where items.count > 0 {
                        dataManager.softDeleteNeighbourHoods(items)
                    }
                }
            }
        }
    }
    
    // MARK: Public methods
    
    /// Returns a singleton instance.
    class func sharedInstance() -> RemoteService {
        return singletonInstance
    }
    
    override func getAuthentication() -> AuthenticationMapping? {
        if let accessToken = appstate.accessToken {
            return ("X-Homehapp-Auth-Token", accessToken)
        } else {
            return nil
        }
    }
    
    /// Retrieves all the homes / stories
    func fetchHomes(completionCallback: (RemoteResponse -> Void)? = nil) {
        
        // fetch deleted homes
        fetchDeletedHomes()
        
        // fetch deleted neighbourhoods
        fetchDeletedNeighbourHoods()
        
        log.debug("Fetching homes..")
        
        var params: [String: AnyObject] = [:]
        if let lastUpdated = appstate.homesLastUpdated {
            params["updatedSince"] = dateFormatter.stringFromDate(lastUpdated)
        }
        
        let url = "\(baseUrl)/api/homes"
        request(.GET, url, parameters: params, encoding: .URL, headers: nil) { response in
            
            if response.success {
                if let json = response.parsedJson,
                    homesJson = json["homes"] as? [[String: AnyObject]] {
                        if homesJson.count == 0 {
                            log.debug("No homes in response.")
                            completionCallback?(response)
                            return
                        }
                        
                        log.debug("\(homesJson.count) home(s) in JSON response.")
                        
                        // Update the last updated -value from the latest updated home
                        if let firstHomeJson = homesJson.first,
                            updatedAtString = firstHomeJson["updatedAt"] as? String,
                            updatedAt = self.dateFormatter.dateFromString(updatedAtString) {
                                if let currentLastUpdated = appstate.homesLastUpdated {
                                    if currentLastUpdated < updatedAt {
                                        appstate.homesLastUpdated = updatedAt
                                    }
                                } else {
                                    appstate.homesLastUpdated = updatedAt
                                }
                        }
                        
                        dataManager.storeHomes(homesJson)
                }
            }
            completionCallback?(response)
        }
    }
    
    /// Sends my home object to server and updates it
    func updateMyHomeOnServer(completionCallback: (RemoteResponse -> Void)? = nil) {
        guard let home = dataManager.findMyHome() else {
            log.error("Failed to find My Home")
            return
        }
        
        let url = "\(baseUrl)/api/homes/\(home.id)"
        let params = createHomeJSON(home)
        request(.PUT, url, parameters: params, encoding: .JSON, headers: nil) { response in
            log.debug("Updating my home completed, success: \(response.success)")

            if response.success {
                dataManager.performUpdates {
                    home.localChanges = false
                }
            }
            
            completionCallback?(response)
        }
    }
    
    /// Adds or removes like for home object
    func likeHome(home: Home, completionCallback: (RemoteResponse -> Void)? = nil) {
        let url = "\(baseUrl)/api/homes/\(home.id)/like"
        request(.PUT, url, parameters: nil, encoding: .JSON, headers: nil) { response in
            log.debug("Like or unlike success, success: \(response.success)")
            
            if response.success {
                if let json = response.parsedJson {
                    dataManager.performUpdates {
                        home.likes = json["likes"]?["total"] as! Int
                    }
                }
            }
            
            completionCallback?(response)
        }
    }
    
    /// Updates my Neighborhood object on server
    func updateMyNeighborhood(neighborhood: Neighborhood, completionCallback: (RemoteResponse -> Void)? = nil) {
        let url = "\(baseUrl)/api/neighborhoods/my/\(neighborhood.id)"
        let params = createNeighborhoodJSON(neighborhood)
        request(.PUT, url, parameters: params, encoding: .JSON, headers: nil) { response in
            log.debug("Updating my neighborhood completed, success: \(response.success)")
            
            if response.success {
                dataManager.performUpdates {
                    neighborhood.localChanges = false
                }
            }
            
            completionCallback?(response)
        }
    }
    
    /// Login current user or register new user to homehapp backend. Returns session to us
    func loginOrRegisterUser(serviceData: UserLoginData, completionCallback: (RemoteResponse -> Void)? = nil) {
        let data: [String: AnyObject] = [
            "service": serviceData.service.rawValue,
            "user": [
                "id": serviceData.id,
                "email": serviceData.email,
                "token": serviceData.token,
                "displayName": serviceData.displayName
            ]
        ]
        
        let url = "\(baseUrl)/api/auth/login"
        request(.POST, url, parameters: data, encoding: .JSON, headers: nil) { response in
            completionCallback?(response)
        }
    }
    
    /// Check from server if user has live session (is authenticated)
    func checkUserSession(completionCallback: (Bool -> Void)) {
        let url = "\(baseUrl)/api/auth/check"
        request(.GET, url, parameters: nil, encoding: .JSON, headers: nil) { response in
            var status = false
            if response.success {
                if let json = response.parsedJson {
                    status = json["status"] as! Bool
                }
            }
            completionCallback(status)
        }
    }
    
    /// Send current user object to server and override existing user there
    func updateCurrentUserOnServer(completionCallback: (RemoteResponse -> Void)? = nil) {
        let user = dataManager.findCurrentUser()
        let data = user!.toJSON()
        let url = "\(baseUrl)/api/auth/user"
        request(.PUT, url, parameters: data, encoding: .JSON, headers: nil) { response in
            log.debug("user updated on server")
            completionCallback?(response)
        }
    }
    
    /// Get home features available for home to be selected
    func fetchHomeFeatures(completionCallback: (RemoteResponse -> Void)? = nil) {
        let url = "\(baseUrl)/api/features"
        request(.GET, url, parameters: nil, encoding: .JSON, headers: nil) { response in
            if response.success {
                if let json = response.parsedJson {
                    log.debug("Server returned features: \(json)")
                    // TODO add capability to server side
                }
            }
        }
    }
    
    /** 
        Preload or Prewarm video by calling it's Cloudinary url
        This causes video transcoding to happen and Cloudinary to populate CDNs
    */
    func prewarmVideo(url: String)  {
        runOnMainThreadAfter(delay: 10, task: { [weak self] in
            self?.request(.GET, url, parameters: nil, encoding: .JSON, headers: nil) { response in
                log.debug("video has been loaded to CDN")
            }
        })
    }
    
    init() {
        var additionalHeaders = [
            "X-Homehapp-Api-Key": "aa43ef70-85e6-4e98-b8fd-9494fd6c02a0",
            "X-Homehapp-Api-Version": "1.0.1",
            "X-Homehapp-Client": getClientId(keychainServiceName)
        ]
        
        if let version = NSBundle.mainBundle().versionNumber,
            build = NSBundle.mainBundle().buildNumber {
                let appVersion = "\(version)_(\(build))"
                additionalHeaders["X-Client-Version"] = appVersion
        }
        
        super.init(backgroundSessionId: "com.homehapp", additionalHeaders: additionalHeaders, timeout: 5)
        log.info("Using baseUrl: \(baseUrl)")
    }
    
}
