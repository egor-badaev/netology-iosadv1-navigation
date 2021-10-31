//
//  LocationService.swift
//  Navigation
//
//  Created by Egor Badaev on 27.08.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate: AnyObject {
    /**
     Called when `CLLocationManager` receives a location update

     - parameters:
        - location: User location
     */
    func received(location: CLLocationCoordinate2D)

    /**
     Called when `CLLocationManager` doesn't have necessary permissions to update user location

     - parameters:
        - permanently: Indicates whether user can change granted permissions

     If authorization status is `.restricted`, user cannot do anything to change authorization status.
     Otherwise we can suggest a solution
     */
    func determinedServiceUnavailable(permanently: Bool)

    /// Called when `CLLocationManager` receives the required permissions to update user location
    func determinedServiceAvailable()
}

class LocationService: NSObject {

    // MARK: - Public properties

    weak var delegate: LocationServiceDelegate?

    // MARK: - Private properties

    private var locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        super.init()
    }

    // MARK: - Public methods

    /// Acquire necessary permissions and start tracking location
    func start() {
        self.locationManager.delegate = self
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        handleAuthorizationStatus(authorizationStatus)
    }

    /// Stop tracking location
    func stop() {
        locationManager.stopUpdatingLocation()
        self.locationManager.delegate = nil
    }

    // MARK: - Private methods

    /// A helper method to choose the right action based on authorization status
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways,
             .authorizedWhenInUse:
            delegate?.determinedServiceAvailable()
            locationManager.startUpdatingLocation()
        case .denied:
            delegate?.determinedServiceUnavailable(permanently: false)
        case .restricted:
            delegate?.determinedServiceUnavailable(permanently: true)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        delegate?.received(location: location)
    }

}
