//
//  AppState.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation

/// Holds 'global' application state.
class AppState {
    // Constants
    private let keyAccessToken = "accessToken"
    private let keyAuthUserId = "keyAuthUserId"
    private let keyHomesLastUpdated = "homesLastUpdated"
    private let keyHomesLastDeleted = "homesLastDeleted"
    private let keyNeighborhoodsLastDeleted = "neighborhoodsLastDeleted"
    private let keyTutorialShown = "tutorialShown"
    private let keyOnboardingShown = "onboardingShown"
    private let keyNeighborhoodTutorialShown = "neighborhoodTutorialShown"

    /// Singleton instance
    private static let singletonInstance = AppState()
    
    /// User defaults instance
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    /// Aspect ratio for the bottom container (height / width) for the most recent home story opened.
    /// This is here as a global state so that it can be accessed even if home story controller is opened 
    /// from elsewhere than Homes list.
    var homeCellBottomContainerAspectRatio: CGFloat = 1
    
    /// Most recently opened Home
    var mostRecentlyOpenedHome: Home? 
    
    /// Returns the singleton instance
    class func sharedInstance() -> AppState {
        return AppState.singletonInstance
    }
        
    /// Logged in user's access token
    var accessToken: String? {
        get {
            return userDefaults.stringForKey(keyAccessToken)
        }
        set {
            // TODO should we save accessToken to keychain instead of userDefaults? Security?
            userDefaults.setObject(newValue, forKey: keyAccessToken)
        }
    }
    
    /// User id for currently authenticated user
    var authUserId: String? {
        get {
            return userDefaults.stringForKey(keyAuthUserId)
        }
        set {
            userDefaults.setObject(newValue, forKey: keyAuthUserId)
        }
    }
    
    /// Timestamp of the 'last updated' home
    var homesLastUpdated: NSDate? {
        get {
            let value = userDefaults.doubleForKey(keyHomesLastUpdated)
            if value > 0 {
                return NSDate(timeIntervalSince1970: value)
            } else {
                return nil
            }
        }
        set {
            if let value = newValue {
                userDefaults.setDouble(value.timeIntervalSince1970, forKey: keyHomesLastUpdated)
            } else {
                userDefaults.removeObjectForKey(keyHomesLastUpdated)
            }
        }
    }
    
    var homesLastDeleted: NSDate? {
        get {
            let value = userDefaults.doubleForKey(keyHomesLastDeleted)
            if value > 0 {
                return NSDate(timeIntervalSince1970: value)
            } else {
                return NSDate() // return current time if one is not stored
            }
        }
        set {
            if let value = newValue {
                userDefaults.setDouble(value.timeIntervalSince1970, forKey: keyHomesLastDeleted)
            } else {
                userDefaults.removeObjectForKey(keyHomesLastDeleted)
            }
        }
    }
    
    var neighborhoodsLastDeleted: NSDate? {
        get {
            let value = userDefaults.doubleForKey(keyNeighborhoodsLastDeleted)
            if value > 0 {
                return NSDate(timeIntervalSince1970: value)
            } else {
                return NSDate() // return current time if one is not stored
            }
        }
        set {
            if let value = newValue {
                userDefaults.setDouble(value.timeIntervalSince1970, forKey: keyNeighborhoodsLastDeleted)
            } else {
                userDefaults.removeObjectForKey(keyNeighborhoodsLastDeleted)
            }
        }
    }
    
    var tutorialShown: String? {
        get {
            return userDefaults.stringForKey(keyTutorialShown)
        }
        set {
            userDefaults.setObject(newValue, forKey: keyTutorialShown)
        }
    }
    
    var neighborhoodTutorialShown: String? {
        get {
            return userDefaults.stringForKey(keyNeighborhoodTutorialShown)
        }
        set {
            userDefaults.setObject(newValue, forKey: keyNeighborhoodTutorialShown)
        }
    }
    
    var onboardingShown: String? {
        get {
            return userDefaults.stringForKey(keyOnboardingShown)
        }
        set {
            userDefaults.setObject(newValue, forKey: keyOnboardingShown)
        }
    }
}
