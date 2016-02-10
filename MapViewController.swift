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
	var appDelegate: AppDelegate!
	var locations: [[String:AnyObject]]?
	
	@IBOutlet weak var mapView: MKMapView!
	
	//MARK: Functions
	func userAlert(title:String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(alertAction)
		
		performUIUpdatesOnMain {
			self.presentViewController(alert, animated: true, completion: nil)
		}
		
	}
	
	func updateLocations(withRequest request:NSURLRequest?) {
		if let request = request {
			let task = appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
				
				let (parsedResult, error) = UIHelper.handleNSURLStudentLocationsResponse(data, response: response, error: error)
				
				guard (error == nil) else {
					self.userAlert("Failed Query", message: (error?.domain)!)
					return
					
				}
				
				//are there any results
				guard let results = parsedResult![ParseHttpClient.Constants.ParseResponseKeys.results] as? [[String:AnyObject]]  else {
					self.userAlert("Failed Query", message: "Could not locate session id")
					return
				}
				
				NSUserDefaults.standardUserDefaults().setValue(results, forKey: "locations")
				self.locations = results
				performUIUpdatesOnMain {
					self.dropPins()
				}
			}
			
			task.resume()
		} else {
			if let _ = locations {
				dropPins()
			}
		}
	}
	
	func dropPins() {
		if let locations = locations {
			for (_, value) in locations.enumerate() {
				let studentDict = value

				let annotation = StudentAnnotation(title: (studentDict["firstName"] ?? "") as! String + " " + ((studentDict["lastName"] ?? "") as! String) , subtitle: (studentDict["mediaURL"] ?? "") as? String, url: (studentDict["mediaURL"] ?? "") as! String, coordinate: CLLocationCoordinate2D(latitude: (studentDict["latitude"]) as! CLLocationDegrees , longitude: (studentDict["longitude"]) as! CLLocationDegrees))
			
				mapView.addAnnotation(annotation)
				
			}
		}
	}
	
	//MARK: View Controller Lifecycle functions
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	
		updateLocations(withRequest: nil)
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.requestWhenInUseAuthorization()
			locationManager.startUpdatingLocation()
		}
		
		mapView.delegate = self
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let request = ParseHttpClient.sharedInstance.getStudentLocations(nil) else {
			print("Unable to retrieve pin locations")
			return
		}
		
		updateLocations(withRequest: request)
	}
}

extension MapViewController : CLLocationManagerDelegate {
	
}

extension MapViewController : MKMapViewDelegate {
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if view.rightCalloutAccessoryView == control {
			let annotation = view.annotation as! StudentAnnotation
			
			UIApplication.sharedApplication().openURL(NSURL(string: annotation.url)!)
		}
	}
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		if !annotation.isKindOfClass(StudentAnnotation) {
			return nil
		}
		
		var view = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationIdentifier")
		
		if view == nil {
			view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier")
		}
		
		view?.canShowCallout = true
		view?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
		
		return view
	}
}