//
//  MapViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 23.08.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import EBFoundation

class MapViewController: UIViewController, AlertPresenter {

    // MARK: - Properties

    /// `CLLocationManager`-based custom location service
    private let locationService: LocationService

    /// A temporary pin to display while user decides what to do
    private var temporaryPin: MKPointAnnotation?

    /// An array containing all manually set pins
    private var userPins: [MKPointAnnotation] = []

    /// A pin to display at the route destination
    private var routeDestination: MKPointAnnotation?

    /// A route drawing
    private var routeOverlay: MKPolyline?

    /// Current user coordinate
    private var currentLocation: CLLocationCoordinate2D?

    /**
     A flag indicating whether map region has been centered on user position

     This flag prevents map being constantly centered on user, allowing for
     easy navigation
     */
    private var isMapRegionSet = false

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.toAutoLayout()

        mapView.mapType = .mutedStandard
        mapView.showsScale = true
        mapView.showsPointsOfInterest = true
        mapView.showsBuildings = true

        return mapView
    }()

    /// A view to display when user location is unavailable
    private lazy var unavailableView: LockMapView = {
        let unavailableView = LockMapView()
        unavailableView.toAutoLayout()

        unavailableView.setButtonAction {
            guard let bundleID = Bundle.main.bundleIdentifier,
                  let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleID)"),
                  UIApplication.shared.canOpenURL(url) else {
                return
            }
            UIApplication.shared.open(url)

        }

        return unavailableView
    }()

    /// Constraints for `unavailableView`
    private lazy var unavailableViewConstraints = [
        unavailableView.topAnchor.constraint(equalTo: view.topAnchor),
        unavailableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        unavailableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        unavailableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ]

    /// A flag indicating whether a view has been 'locked' (`unavailableView` has been shown)
    private var isViewLocked = false

    // MARK: - Initialization

    init(locationService: LocationService) {
        self.locationService = locationService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        locationService.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationService.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationService.stop()
    }

    //MARK: - Actions

    @objc private func mapLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            temporaryPin = createPin(at: touchPoint)
            displayTouchActionRequest(at: touchPoint)
        }
    }

    // MARK: - UI

    private func setupUI() {
        view.addSubview(mapView)

        let constraints = [
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressed(_:)))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
    }

    /// Displays action sheet with "Get Directions" and "Pin Location" options
    private func displayTouchActionRequest(at touchPoint: CGPoint) {

        let alertController = UIAlertController(title: "Выберите действие", message: nil, preferredStyle: .actionSheet)

        let routeAction = UIAlertAction(title: "Проложить маршрут", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let temporaryPin = self.temporaryPin {
                self.createRoute(to: temporaryPin)
            }
        }
        alertController.addAction(routeAction)

        let pinAction = UIAlertAction(title: "Поставить точку", style: .default) { [weak self] _ in
            self?.displayPinRequest(at: touchPoint)
        }
        alertController.addAction(pinAction)

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.removeTemporaryPin()
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Displays alert with option to set Pin name and description
    private func displayPinRequest(at touchPoint: CGPoint) {
        let alertController = UIAlertController(title: "Поставить точку", message: "Введите название и подзаголовок", preferredStyle: .alert)

        alertController.addTextField { titleTextField in
            titleTextField.placeholder = "Название точки"
        }

        alertController.addTextField { subtitleTextField in
            subtitleTextField.placeholder = "Описание точки"
        }

        let addPinAction = UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            self?.removeTemporaryPin()
            let title = alertController.textFields?[0].text
            let subtitle = alertController.textFields?[1].text
            self?.createPin(at: touchPoint, temporary: false, title: title, subtitle: subtitle)
        }

        alertController.addAction(addPinAction)

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.removeTemporaryPin()
        }
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    /// Resets map view to initial scale and centers around user position
    private func resetMapRegion(for location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Routes

    /// Creates a route from current location to destination
    private func createRoute(to destination: MKPointAnnotation) {

        clearRoute(resettingMap: false)

        guard let sourceLocation = currentLocation else { return }
        self.routeDestination = destination
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) -> Void in
            
            guard let response = response else {
                
                var errorMessage = "Невозможно построить маршрут"
                
                if let error = error {
                    errorMessage += ": \(error.localizedDescription)"
                }
                
                self?.presentErrorAlert(errorMessage)
                self?.removeTemporaryPin()
                return
            }
            
            let route = response.routes[0]
            
            self?.routeOverlay = route.polyline
            self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            self?.mapView.setUserTrackingMode(.followWithHeading, animated: true)
        }
    }

    /// Remove route overlay and clear all contiguous properties; optionally reset map view
    private func clearRoute(resettingMap shouldResetMapRegion: Bool) {
        if let routeDestination = self.routeDestination,
           !userPins.contains(routeDestination) {
            mapView.removeAnnotation(routeDestination)
        }

        self.routeDestination = nil

        if let routeOverlay = self.routeOverlay {
            mapView.removeOverlay(routeOverlay)
            self.routeOverlay = nil
            mapView.setUserTrackingMode(.none, animated: true)
        }

        if let currentLocation = self.currentLocation,
           shouldResetMapRegion {
            resetMapRegion(for: currentLocation)
        }
    }

    // MARK: - Pins

    /**
     Add pin to mapView

     - parameters:
        - touchPoint: `CGPoint` to place the pin at
        - temporary: A flag indicating whether the pin is temporary (see **Descussion**). Defaults to `true`
        - title: Pin title (optional)
        - subtitle: Pin subtitle (optional)

     A pin may be _temporary_ – an automatically created pin for user to see while he decides what to do with it.
     Such pin would be removed immediately if no action is taken (nor route neither pin).
     If user builds a route to a temporary pin, this pin is always cleared upon clearing route.

     */
    @discardableResult
    private func createPin(at touchPoint: CGPoint, temporary: Bool = true, title: String? = nil, subtitle: String? = nil) -> MKPointAnnotation {
        let touchCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        let annotation = MKPointAnnotation()
        annotation.coordinate = touchCoordinates
        annotation.title = title
        annotation.subtitle = subtitle

        mapView.addAnnotation(annotation)

        if !temporary {
            userPins.append(annotation)
        }

        return annotation
    }

    /// Removes temporary pin from map and resets object
    private func removeTemporaryPin() {
        if let tmpPin = temporaryPin {
            mapView.removeAnnotation(tmpPin)
        }
        temporaryPin = nil
    }

    /// Remove all pins from map and reset all pin-storing properties
    private func removeAllPins() {
        mapView.removeAnnotations(mapView.annotations)
        userPins.removeAll()
        temporaryPin = nil
        routeDestination = nil
    }

}

// MARK: - LocationServiceDelegate

extension MapViewController: LocationServiceDelegate {
    func received(location: CLLocationCoordinate2D) {
        if !isMapRegionSet {
            resetMapRegion(for: location)
            isMapRegionSet = true
        }

        currentLocation = location
    }

    func determinedServiceUnavailable(permanently: Bool) {
        isViewLocked = true
        view.addSubview(unavailableView)
        NSLayoutConstraint.activate(unavailableViewConstraints)
        unavailableView.makeButton(visible: !permanently)
    }

    func determinedServiceAvailable() {
        if isViewLocked {
            NSLayoutConstraint.deactivate(unavailableViewConstraints)
            unavailableView.removeFromSuperview()
            isViewLocked = false
        }
    }

}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        guard let pin = view.annotation as? MKPointAnnotation else { return }

        let alertController = UIAlertController(title: pin.title ?? "Точка", message: pin.subtitle, preferredStyle: .actionSheet)

        let deleteActionTitle: String

        if pin == self.routeDestination {
            if self.userPins.contains(pin) {
                let clearRouteAction = UIAlertAction(title: "Очистить маршрут", style: .destructive) { [weak self] _ in
                    self?.clearRoute(resettingMap: true)
                    mapView.deselectAnnotation(pin, animated: true)
                }
                alertController.addAction(clearRouteAction)
            }

            deleteActionTitle = "Удалить точку и очистить маршрут"
        } else {
            let routeAction = UIAlertAction(title: "Проложить маршрут", style: .default) { [weak self] _ in
                self?.createRoute(to: pin)
                mapView.deselectAnnotation(pin, animated: true)
            }
            alertController.addAction(routeAction)

            deleteActionTitle = "Удалить точку"
        }

        let deleteAction = UIAlertAction(title: deleteActionTitle, style: .destructive) { [weak self] _ in
            mapView.removeAnnotation(pin)
            self?.userPins.removeAll { $0 == pin }
            if pin == self?.routeDestination {
                self?.clearRoute(resettingMap: true)
            }
        }
        alertController.addAction(deleteAction)

        var deleteAllActionTitle = "Удалить все точки"
        if let _ = routeDestination {
            deleteAllActionTitle += " и очистить маршрут"
        }
        let deleteAllAction = UIAlertAction(title: deleteAllActionTitle, style: .destructive) { [weak self] _ in
            self?.removeAllPins()
            self?.clearRoute(resettingMap: true)
        }
        alertController.addAction(deleteAllAction)

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            mapView.deselectAnnotation(pin, animated: true)
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .systemBlue.withAlphaComponent(0.75)
        renderer.lineWidth = 6.0

        return renderer
    }
}
