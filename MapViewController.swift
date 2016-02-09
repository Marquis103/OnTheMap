//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
	
	let locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.requestWhenInUseAuthorization()
			locationManager.startUpdatingLocation()
		}
		
		
	}
}

extension MapViewController : CLLocationManagerDelegate {
	
}