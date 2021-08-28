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

class MapViewController: UIViewController {

    // MARK: - Properties

    private let locationService: LocationService

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.toAutoLayout()
        return mapView
    }()

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

    private lazy var unavailableViewConstraints = [
        unavailableView.topAnchor.constraint(equalTo: view.topAnchor),
        unavailableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        unavailableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        unavailableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ]

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationService.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationService.stop()
    }

    // MARK: - Private methods

    private func setupUI() {
        view.addSubview(mapView)

        let constraints = [
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
    }

    @objc private func pinLocation(gestureRecognizer: UILongPressGestureRecognizer) {

        if gestureRecognizer.state == .began {

            let touchPoint = gestureRecognizer.location(in: self.mapView)

            let alertController = UIAlertController(title: "Поставить точку", message: "Введите название и подзаголовок", preferredStyle: .alert)

            alertController.addTextField { titleTextField in
                titleTextField.placeholder = "Название точки"
            }

            alertController.addTextField { subtitleTextField in
                subtitleTextField.placeholder = "Описание точки"
            }

            let addPinAction = UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
                let title = alertController.textFields?[0].text
                let subtitle = alertController.textFields?[1].text
                self?.createPin(at: touchPoint, with: title, subtitle: subtitle)
            }

            alertController.addAction(addPinAction)

            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func createPin(at touchPoint: CGPoint, with title: String?, subtitle: String?) {
        let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)

        let annotation = MKPointAnnotation()
        annotation.coordinate = touchCoordinates
        annotation.title = title
        annotation.subtitle = subtitle

        self.mapView.addAnnotation(annotation)
    }

}

// MARK: - LocationServiceDelegate

extension MapViewController: LocationServiceDelegate {
    func received(location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
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

