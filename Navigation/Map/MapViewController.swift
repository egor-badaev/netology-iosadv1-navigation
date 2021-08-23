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

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.toAutoLayout()
        return mapView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(mapView)

        let constraints = [
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
