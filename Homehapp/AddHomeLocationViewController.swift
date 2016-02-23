//
//  AddHomeLocationViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 5.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import GoogleMaps

class AddHomeLocationViewController: BaseViewController, GMSMapViewDelegate {

    @IBOutlet private weak var mapContainerView: UIView!
    
    private var home: Home? = nil
    
    private var mapView: GMSMapView? = nil
    private var camera: GMSCameraPosition? = nil
    private var homeMarker: GMSMarker? = nil
    
    /// Initial home coordinate or coordinate which user selected from the map
    private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    // MARK: IBActions
    
    @IBAction func doneButtonPressed(sender: UIButton!) {
        if let selectedCoordinate = selectedCoordinate {
            locationService.reverseGeocodeCoordinate(selectedCoordinate, completionCallback: { [weak self] (response) -> Void in
                dataManager.performUpdates({
                    self?.home!.locationLatitude = selectedCoordinate.latitude
                    self?.home!.locationLongitude = selectedCoordinate.longitude
                    if response != nil {
                        self?.home!.addressCountry = response!.country
                        self?.home!.addressCity = response!.city
                        self?.home!.addressSublocality = response!.sublocality
                    }
                })
                self?.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    @IBAction func backButtonPressed(sender: UIButton!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Private methods
    
    /// Add user home annoation on the map. Home annotation is pale circle
    private func addUserHomeAnnotation() {
        if home != nil && selectedCoordinate != nil {
            homeMarker = GMSMarker(position: selectedCoordinate!)
            homeMarker!.title = home!.title
            homeMarker!.icon = UIImage(named: "icon_map_pin_circle")
            homeMarker!.map = mapView
            
            if camera == nil {
                camera = GMSCameraPosition.cameraWithTarget(selectedCoordinate!, zoom: 12)
            } else {
                let cameraUpdate = GMSCameraUpdate.setTarget(selectedCoordinate!)
                mapView?.animateWithCameraUpdate(cameraUpdate)
            }
        }
    }
    
    // MARK GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        mapView?.clear()
        
        // We move annotation a bit due to the fact that our annotation is circle instead on pin
        // and thus center of circle is a bit different than pin position
        let scale: Double = Double(mapView.maxZoom - mapView.camera.zoom) + 1
        selectedCoordinate = CLLocationCoordinate2DMake(coordinate.latitude - 0.0005*scale, coordinate.longitude - 0.0005*scale)
        addUserHomeAnnotation()
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        camera = GMSCameraPosition.cameraWithLatitude(0, longitude: 0, zoom: 0)
        self.view.layoutIfNeeded()
        mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, mapContainerView.width, mapContainerView.height), camera: camera)
        mapView!.delegate = self
        mapView?.setMinZoom(0, maxZoom: 14)
        mapContainerView.addSubview(mapView!)
        
        home = appstate.mostRecentlyOpenedHome
        if home!.locationLatitude != 0.0 && home!.locationLongitude != 0.0 {
            selectedCoordinate = CLLocationCoordinate2D(latitude: home!.locationLatitude, longitude: home!.locationLongitude)
            camera = GMSCameraPosition.cameraWithTarget(selectedCoordinate!, zoom: 12)
            mapView?.camera = camera
            addUserHomeAnnotation()
        }
    }
    
}