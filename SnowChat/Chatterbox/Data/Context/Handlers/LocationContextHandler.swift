//
//  LocationContextHandler.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import CoreLocation

class LocationContextHandler: BaseContextHandler, DataFetchable, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()
    private var authorizationCompletion: ((Bool) -> Void)?
    private(set) var locationData: LocationContextData?
    
    override var isAuthorized: Bool {
        didSet {
            authorizationCompletion?(isAuthorized)
        }
    }
    
    required init(contextItem: ContextItem) {
        super.init(contextItem: contextItem)
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func authorize(completion: @escaping (Bool) -> Void) {
        authorizationCompletion = completion
        authorizeLocation()
    }
    
    private func authorizeLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            isAuthorized = false
            authorizationCompletion = nil
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func stopLocationManager() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard nil != Bundle.main.infoDictionary?["NSLocationWhenInUseUsageDescription"] else {
            isAuthorized = false
            authorizationCompletion = nil
            return
        }
        
        isAuthorized = (status == .authorizedWhenInUse)
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
        
        // Don't update authorization status (not supported right now on the server)
        authorizationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // For now we don't support periodic updates so we want to stop location updates immediately
        stopLocationManager()
        
        guard let currentLocation = locations.last else {
            return
        }
        
        locationData?.latitude = currentLocation.coordinate.latitude
        locationData?.longitude = currentLocation.coordinate.longitude
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks, error) -> Void in
            if error == nil {
                let placemark = placemarks?.first
                self?.locationData?.address = (placemark?.addressDictionary?["FormattedAddressLines"] as? Array)?.joinedWithCommaSeparator()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        stopLocationManager()
        Logger.default.logDebug("CLLocation error: \(error)")
    }
}
