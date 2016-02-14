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
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	
	@IBOutlet weak var mapView: MKMapView!
	
	//MARK: Actions
	
	@IBAction func addStudentLocation(sender: UIBarButtonItem) {
		guard let uniqueId = appDelegate.uniqueId else {
			userAlert("Add Location Error", message: "Unique Key not identified.  Please login again!")
			return
		}
		
		if let request = ParseHttpClient.sharedInstance.getStudentLocation(uniqueId) {
			let task = appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
				
				let (parsedResult, error) = UIHelper.handleNSURLStudentLocationsResponse(data, response: response, error: error)
				
				guard (error == nil) else {
					self.userAlert("Add Location Error", message: (error?.domain)!)
					return
					
				}
				
				//are there any results
				let results = parsedResult![ParseHttpClient.Constants.ParseResponseKeys.results] as? [[String:AnyObject]]
				guard results?.count > 0   else {
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("addStudentLocationSegue", sender: nil)
					}
					
					return
				}
				
				print(results)
				
				//if the student object id --hasn't made a post is nil update it if a value exists
				if self.appDelegate.student?.objectId == nil {
					self.appDelegate.student?.objectId = results!.first!["objectId"] as? String
					let data = NSKeyedArchiver.archivedDataWithRootObject(self.appDelegate.student!)
					NSUserDefaults.standardUserDefaults().setObject(data, forKey: "student")
				}
				
				let alert = UIAlertController(title: "Confirm Location Add", message: "You have already posted a student location.  Would you like to overwrite your current location?", preferredStyle: .Alert)
				let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
				let overwriteAction = UIAlertAction(title: "Overwrite", style: .Default, handler: { (action) -> Void in
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("addStudentLocationSegue", sender: nil)
					}
				})
				
				alert.addAction(overwriteAction)
				alert.addAction(cancelAction)
				performUIUpdatesOnMain {
					self.presentViewController(alert, animated: true, completion: nil)
				}
			}
			
			task.resume()
			
		}
		
	}
	
	
	@IBAction func refreshStudentLocations(sender: UIBarButtonItem) {
		guard let request = ParseHttpClient.sharedInstance.getStudentLocations(nil) else {
			print("Unable to retrieve pin locations")
			return
		}
		
		loadingView.hidden = false
		activityIndicatorView.startAnimating()
		UIApplication.sharedApplication().beginIgnoringInteractionEvents()
		
		//clear current pins
		locations?.removeAll()
		
		updateLocations(withRequest: request)
	}
	
	@IBAction func logUserOut(sender: UIBarButtonItem) {
		let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		locations?.removeAll()
		appDelegate.sessionId = nil
		NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
		NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
		
		if let request = UdacityHttpClient.sharedInstance.getLogoutSessionRequest() {
			let task = appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
				
				let (parsedResult, error) = UIHelper.handleNSURLSessionLogoutResponse(data, response: response, error: error)
				
				guard (error == nil) else {
					self.userAlert("Failed Query", message: (error?.domain)!)
					return
					
				}
				
				//is the session token in the parsed results
				guard let sessionToken = parsedResult![UdacityHttpClient.Constants.UdacityResponseKeys.session]!![UdacityHttpClient.Constants.UdacityResponseKeys.session_id] as? String else {
					self.userAlert("Login Unsuccessful", message: "Could not locate session id")
					return
				}
				
				performUIUpdatesOnMain {
					self.presentViewController(loginViewController, animated: true, completion: nil)
				}
			}
			
			task.resume()
			
		}
	}
	
	
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
					self.locations = nil
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
		performUIUpdatesOnMain {
			if self.activityIndicatorView.isAnimating() {
				self.loadingView.hidden = true
				self.activityIndicatorView.stopAnimating()
			}
			
			if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
				UIApplication.sharedApplication().endIgnoringInteractionEvents()
			}
		}
		
		if let locations = locations {
			for (_, value) in locations.enumerate() {
				let studentDict = value

				let annotation = StudentAnnotation(title: (studentDict["firstName"] ?? "") as! String + " " + ((studentDict["lastName"] ?? "") as! String) , subtitle: (studentDict["mediaURL"] ?? "") as? String, url: (studentDict["mediaURL"] ?? "") as! String, coordinate: CLLocationCoordinate2D(latitude: (studentDict["latitude"]) as! CLLocationDegrees , longitude: (studentDict["longitude"]) as! CLLocationDegrees))
		
				mapView.addAnnotation(annotation)
				
			}
		}
	}
	
	//MARK: View Controller Lifecycle functions
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		loadingView = UIHelper.activityIndicatorViewLoadingView(self.view.center)
		loadingView.hidden = true
		
		activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
		activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2);
		loadingView.addSubview(activityIndicatorView)
		view.addSubview(loadingView!)
		activityIndicatorView.hidesWhenStopped = true
		activityIndicatorView.activityIndicatorViewStyle = .WhiteLarge
		
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
		
		guard appDelegate.sessionId != nil else {
			let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
			locations?.removeAll()
			NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
			NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
			presentViewController(loginViewController, animated: true, completion: nil)
			
			return
		}
		
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