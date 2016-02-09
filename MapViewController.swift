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

	@IBOutlet weak var navigationBar: UINavigationBar!
	
	let locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		navigationBar.delegate = self
		
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

extension MapViewController : UINavigationBarDelegate {
	func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
		return .TopAttached
	}
}