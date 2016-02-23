//
//  LocationService.swift
//  Homehapp
//
//  Created by Lari Tuominen on 1.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import Foundation
import QvikNetwork
import MapKit
import GoogleMaps

struct ReverseGeocodeResponse {
    var country: String = ""
    var city: String = ""
    var sublocality: String = ""
}

class LocationService: RemoteService {

    private static let singletonInstance = LocationService()

    // MARK: Public methods
    
    /// Returns a shared (singleton) instance.
    override class func sharedInstance() -> LocationService {
        return singletonInstance
    }
    
    /// https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670,151.1957&radius=3000&types=<type>&key=<your-api-key>
    func fetchPlaces(pageToken: String?, centerCoordinate: CLLocationCoordinate2D, type: String, completionCallback: (RemoteResponse -> Void)? = nil) {
        var url = ""
        if let pageToken = pageToken {
            url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(centerCoordinate.latitude),\(centerCoordinate.longitude)&radius=3000&types=\(type)&pagetoken=\(pageToken)&key=AIzaSyDPzTlDi9dZ2otR47DLwUPHp4Y2Ge9VQ-U".urlEncoded!
        } else {
            url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(centerCoordinate.latitude),\(centerCoordinate.longitude)&radius=3000&types=\(type)&key=AIzaSyDPzTlDi9dZ2otR47DLwUPHp4Y2Ge9VQ-U".urlEncoded!
            
        }
        remoteService.request(.GET, url, parameters: nil, encoding: .JSON, headers: nil) { response in
            completionCallback?(response)
        }
    }
    
    /// Reverse geocodes given coordinate and calls completionCallback with first placemark found
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D, completionCallback: (ReverseGeocodeResponse? -> Void)) {
        let location = CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks where error == nil {
                var country = ""
                var city = ""
                var sublocality = ""
                
                if placemarks[0].country != nil {
                    country = placemarks[0].country!
                }
                if placemarks[0].locality != nil {
                    city = placemarks[0].locality!
                }
                if placemarks[0].subLocality != nil {
                    sublocality = placemarks[0].subLocality!
                }
                
                let response = ReverseGeocodeResponse(country: country, city: city, sublocality: sublocality)
                completionCallback(response)
            }
            completionCallback(nil)
        }
    }
    
}
