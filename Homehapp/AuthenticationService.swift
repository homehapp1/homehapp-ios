//
//  AuthenticationService.swift
//  Homehapp
//
//  Created by Jerry Jalava on 03/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import QvikNetwork

enum LoginService: String {
    case Facebook = "facebook"
    case Google = "google"
}

struct UserLoginData {
    var id: String
    var token: String
    var email: String
    var displayName: String = ""
    var service: LoginService = .Facebook
}

/// Notification sent when user logs out
let userLogoutNotification = "userLogoutNotification"

/// Error codes if user or home not found
let userNotFoundErrorCode = 1001
let homeNotFoundErrorCode = 1002

class AuthenticationService {
    private static let singletonInstance = AuthenticationService()
    
    /// Returns a shared (singleton) instance.
    class func sharedInstance() -> AuthenticationService {
        return singletonInstance
    }
    
    // MARK: Public methods
    
    func registerOrLoginUser(data: UserLoginData, completionCallback: ((NSDictionary?, NSError?) -> Void)) {
        remoteService.loginOrRegisterUser(data) { (response) in
            if response.success {
                if let json = response.parsedJson, session = json["session"], home = json["home"] as? NSDictionary {
                    appstate.accessToken = session["token"] as? String
                    if let user = session["user"] as? [String: AnyObject] {
                        var mutableDict = user as [String: AnyObject]
                        
                        switch data.service {
                        case .Facebook:
                            mutableDict["fbUserId"] = data.id
                        case .Google:
                            mutableDict["googleUserId"] = data.id
                        }
                        
                        // Store user's home information from server.
                        // Server creates home for user if home does not exists yet while user logging in
                        dataManager.storeHomes([home])
                        
                        // Store user information from server
                        dataManager.updateCurrentUserFromJSON(mutableDict)
                    
                        completionCallback(session as? NSDictionary, nil)

                    }
                } else {
                    let error = NSError(domain: "com.homehapp.user.not.found", code: userNotFoundErrorCode, userInfo: nil)
                    completionCallback(nil, error)
                }
            } else {
                completionCallback(nil, response.nsError)
            }
        }
    }
    
    /// Returns true if we have user session token
    func isUserLoggedIn() -> Bool {
        return (appstate.accessToken != nil)
    }
    
    /// Asynchronous way to check wether our stored token is still valid
    func isUserLoggedInAsync(onComplete: (Bool -> Void)) {
        remoteService.checkUserSession(onComplete)
    }
    
    /// Clear user access token from appstate and delete all data stored in database
    func logoutUser() {
        appstate.authUserId = nil
        appstate.accessToken = nil
        appstate.homesLastUpdated = nil
        appstate.mostRecentlyOpenedHome = nil
        dataManager.deleteAll()
    }
}
