//
//  HomeMapView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import GoogleMaps

class HomeMapView: UIView, EditableHomeInfoView {

    @IBOutlet private weak var mapContainerView: UIView!
    
    /// Add location button that opens add location view
    @IBOutlet private weak var addLocationButton: UIButton!
    
    @IBOutlet private weak var mapOverlayView: UIView!
    
    @IBOutlet private weak var stationsButton: UIButton!
    @IBOutlet private weak var restaurantsButton: UIButton!
    @IBOutlet private weak var schoolsButton: UIButton!
    @IBOutlet private weak var cafesButton: UIButton!
    
    private var mapView: GMSMapView? = nil
    
    private var selectedMapMarkerImage: UIImage? = nil
    
    /// Places API returns max 60 establishments and 20 at a time
    private let maxPlacesFetchCount = 3
    
    /// Callback to be called when user pressed add location button
    var addLocationcallback: (Void -> Void)?
    
    var home: Home? = nil {
        didSet {
            guard let home = home else {
                log.debug("Home cannot be nil")
                return
            }
            
            if mapView == nil {
                let camera = GMSCameraPosition.cameraWithLatitude(0.0, longitude: 0.0, zoom: 0)
                let mapWidth = UIScreen.mainScreen().bounds.width - 2 * 20 // 20 is margin
                mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, mapWidth, mapWidth), camera: camera)
                mapContainerView.cornerRadius = mapWidth / 2
                mapContainerView.clipsToBounds = true
                mapView!.cornerRadius = mapWidth / 2
                mapView!.clipsToBounds = true
                mapContainerView.addSubview(mapView!)
            }
            
            if home.locationLatitude != 0.0 && home.locationLongitude != 0.0 {
                
                // Set map view center coordinate
                let homeCoordinate = CLLocationCoordinate2D(latitude: home.locationLatitude, longitude: home.locationLongitude)
                let camera = GMSCameraPosition.cameraWithTarget(homeCoordinate, zoom: 12)
                mapView?.camera = camera
                
                addUserHomeAnnotation()
                mapView?.setMinZoom(0, maxZoom: 14)
                
            }
        }
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        if editMode {
            addLocationButton.hidden = false
            mapOverlayView.hidden = false
        } else {
            addLocationButton.hidden = true
            mapOverlayView.hidden = true
        }
    }
    
    // MARK: Private methods
    
    private func addUserHomeAnnotation() {
        if home != nil {
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: home!.locationLatitude, longitude: home!.locationLongitude))
            marker.title = home!.title
            marker.icon = UIImage(named: "icon_map_pin_circle")
            marker.map = mapView
        }
    }
    
    private func removeMapAnnotations(retainHome: Bool) {
        mapView?.clear()
        if retainHome {
            addUserHomeAnnotation()
        }
    }
    
    private func deselectMapButtons() {
        stationsButton.setImage(UIImage(named:"icon_map_station"), forState: UIControlState.Normal)
        restaurantsButton.setImage(UIImage(named:"icon_map_restaurant"), forState: UIControlState.Normal)
        schoolsButton.setImage(UIImage(named:"icon_map_school"), forState: UIControlState.Normal)
        cafesButton.setImage(UIImage(named:"icon_map_cafe"), forState: UIControlState.Normal)
    }
    
    /**
     Fetch places with given type from Google Places API.
     This method is called recursively if we have pageToken and if count is less than maxPlacesFetchCount
    */
    private func fetchPlaces(pageToken: String?, type: String, count: Int) {
        if count == 0 {
            removeMapAnnotations(true)
        }
        
        if let home = home {
            locationService.fetchPlaces(pageToken, centerCoordinate: CLLocationCoordinate2D(latitude: home.locationLatitude, longitude: home.locationLongitude), type: type, completionCallback: { [weak self] (response) -> Void  in
                if response.success {
                    if let json = response.parsedJson where json["status"] as? String == "OK" {
                        if let results = json["results"] as? NSArray {
                            for result in results {
                                if let result = result as? NSDictionary {
                                    self?.addEstablishmentMarker(result)
                                }
                            }
                        }
                        if let nextPageToken = json["next_page_token"] as? String where count < self?.maxPlacesFetchCount {
                            // Fetch after delay because next page in places API is not immediate available. Google places API works that way and is known issue
                            runOnMainThreadAfter(delay: 2.0, task: {
                                self?.fetchPlaces(nextPageToken, type: type, count: count + 1)
                            })
                        }
                    }
                }
            })
        }
    }
    
    /// Add establishment marker on map based on it's info
    private func addEstablishmentMarker(info: NSDictionary) {
        if let title = info["name"] as? String,
            geometry = info["geometry"] as? NSDictionary,
            vicinity = info["vicinity"] as? String {
            if let location = geometry["location"] as? NSDictionary {
                if let lat = location["lat"] as? Double, lng = location["lng"] as? Double {
                    let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    marker.title = title
                    marker.snippet = vicinity
                    marker.icon = selectedMapMarkerImage
                    marker.map = mapView
                }
            }
        }
    }
    
    // MARK: IBActions
    
    @IBAction func schoolsButtonPressed(button: UIButton) {
        deselectMapButtons()
        schoolsButton.setImage(UIImage(named:"icon_map_school_active"), forState: UIControlState.Normal)
        selectedMapMarkerImage = UIImage(named: "icon_map_dot_yellow")
        fetchPlaces(nil, type: "school|university", count: 0)
    }
    
    @IBAction func transportationButtonPressed(button: UIButton) {
        deselectMapButtons()
        stationsButton.setImage(UIImage(named:"icon_map_station_active"), forState: UIControlState.Normal)
        selectedMapMarkerImage = UIImage(named: "icon_map_dot_blue")
        fetchPlaces(nil, type: "subway_station|train_station|bus_station", count: 0)
    }
    
    @IBAction func restaurantsButtonPressed(button: UIButton) {
        deselectMapButtons()
        restaurantsButton.setImage(UIImage(named:"icon_map_restaurant_active"), forState: UIControlState.Normal)
        selectedMapMarkerImage = UIImage(named: "icon_map_dot_red")
        fetchPlaces(nil, type: "restaurant", count: 0)
    }
    
    @IBAction func cafeButtonPressed(button: UIButton) {
        deselectMapButtons()
        cafesButton.setImage(UIImage(named:"icon_map_cafe_active"), forState: UIControlState.Normal)
        selectedMapMarkerImage = UIImage(named: "icon_map_dot_brown")
        fetchPlaces(nil, type: "cafe", count: 0)
    }
    
    @IBAction func addLocationButtonPressed(button: UIButton) {
        addLocationcallback!()
    }
    
    // MARK: Lifecycle
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeMapView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
    
    
}
