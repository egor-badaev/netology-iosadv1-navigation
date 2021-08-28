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
    func received(location: CLLocationCoordinate2D)
    func determinedServiceUnavailable(permanently: Bool)
    func determinedServiceAvailable()
}

class LocationService: NSObject {

    // MARK: - Public properties

    weak var delegate: LocationServiceDelegate?

    // MARK: - Private properties

    private var authorizationCompletion: (() -> Void)?

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        return locationManager
    }()

    // MARK: - Public methods

    func start() {
        authorize { [weak self] in
            self?.delegate?.determinedServiceAvailable()
            self?.locationManager.startUpdatingLocation()
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Private methods

    private func authorize(completion: @escaping () -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        authorizationCompletion = completion
        handleAuthorizationStatus(authorizationStatus)

    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways,
             .authorizedWhenInUse:
            authorizationCompletion?()
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
        switch status {
        case .authorizedAlways,
             .authorizedWhenInUse:
            authorizationCompletion?()
            return
        case .denied:
            delegate?.determinedServiceUnavailable(permanently: false)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        delegate?.received(location: location)
    }

}
