//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit
import FBSDKLoginKit
import ReachabilitySwift

class MapViewController: UIViewController {
	
	let locationManager = CLLocationManager()
	//var locations: [[String:AnyObject]]?
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	var reachability:Reachability?
	weak var appDelegate: AppDelegate!
	var studentTabBar:StudentTabBarController!
	
	@IBOutlet weak var mapView: MKMapView!
	
	//MARK: Actions
	
	@IBAction func addStudentLocation(sender: UIBarButtonItem) {
		if reachability!.isReachable() == false {
			userAlert("Unable to Add Location", message: "Unable to connect to the Internet")
			return
		}
		else {
			if let _ = self.appDelegate.currentStudent?.objectId where self.appDelegate.currentStudent?.objectId != "" {
				let alert = UIAlertController(title: "Confirm Location Add", message: "You have already posted a student location.  Would you like to overwrite your current location?", preferredStyle: .Alert)
				let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
				let overwriteAction = UIAlertAction(title: "Overwrite", style: .Default, handler: { (action) -> Void in
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("addStudentLocationSegue", sender: nil)
					}
				})
				
				alert.addAction(overwriteAction)
				alert.addAction(cancelAction)
				
				self.presentViewController(alert, animated: true, completion: nil)
				
				
				return
			}
			
			guard let uniqueId = appDelegate.uniqueId else {
				userAlert("Add Location Error", message: "Unique Key not identified.  Please login again!")
				return
			}
			
			
			HttpClient.sharedInstance.getStudentLocation(nil, uniqueKey: uniqueId) { (result, error) -> Void in
				guard error == nil else {
					self.userAlert("Could Not Refresh", message: (error?.userInfo["NSLocalizedDescriptionKey"]!)! as! String)
					return
				}
				
				let results = result![HttpClient.Constants.ParseResponseKeys.results] as? [[String:AnyObject]]
				
				guard results?.count > 0   else {
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("addStudentLocationSegue", sender: nil)
					}
					
					return
				}
				
				//if the student object id --hasn't made a post is nil update it if a value exists
				if self.appDelegate.currentStudent?.objectId == nil || self.appDelegate.currentStudent?.objectId == "" {
					self.appDelegate.currentStudent?.objectId = (results!.first!["objectId"] as? String)!
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
		}
	}
	
	
	@IBAction func refreshStudentLocations(sender: UIBarButtonItem) {
		if reachability!.isReachable() == false {
			userAlert("Refresh Failed", message: "Internet connection available to refresh")
			return
		}
		
		HttpClient.sharedInstance.getStudentLocations(nil) { (result, error) -> Void in
			self.loadingView.hidden = false
			self.activityIndicatorView.startAnimating()
			UIApplication.sharedApplication().beginIgnoringInteractionEvents()
			
			guard error == nil else {
				self.userAlert("Could Not Refresh", message: (error?.userInfo["NSLocalizedDescriptionKey"]!)! as! String)
				return
			}
			
			if let result = result {
				//clear current pins
				self.studentTabBar!.students.removeAllStudents()
				self.updateLocations(result)
			} else {
				self.studentTabBar.students.removeAllStudents()
			}
		}
	}
	
	@IBAction func logUserOut(sender: UIBarButtonItem) {
		let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		
		appDelegate.sessionId = nil
		NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
		NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
		NSUserDefaults.standardUserDefaults().removeObjectForKey("uniqueId")
		
		FBSDKAccessToken.setCurrentAccessToken(nil)
		
		presentViewController(loginViewController, animated: true, completion: nil)
	}
	
	func addReachability() {
		do {
			reachability = try Reachability.reachabilityForInternetConnection()
		} catch {
			print("Unable to create Reachability")
			return
		}
		
		reachability!.whenReachable = { reachability in
			performUIUpdatesOnMain {
				self.loadingView.hidden = true
				self.activityIndicatorView.stopAnimating()
				UIApplication.sharedApplication().endIgnoringInteractionEvents()
			}
			
			HttpClient.sharedInstance.getStudentLocations(nil) { (result, error) -> Void in
				if let result = result {
					self.updateLocations(result)
				} else {
					self.studentTabBar.students.removeAllStudents()
					
					performUIUpdatesOnMain {
						if self.activityIndicatorView.isAnimating() {
							self.loadingView.hidden = true
							self.activityIndicatorView.stopAnimating()
						}
						
						if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
							UIApplication.sharedApplication().endIgnoringInteractionEvents()
						}
					}
				}
			}
		}
		
		do {
			try reachability!.startNotifier()
		} catch {
			print("Can't start reachability notifier")
		}
	}
	
	deinit {
		reachability?.stopNotifier()
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
	
	func updateLocations(parsedResult:AnyObject?) {
		if let _ = parsedResult {
			let results = parsedResult![HttpClient.Constants.ParseResponseKeys.results] as? [[String:AnyObject]]
			
			studentTabBar.students.addStudents(withJsonData: results!)
		}
		
		performUIUpdatesOnMain {
			self.dropPins()
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
		
		
		for student in studentTabBar.students.getStudents() {
			let annotation = StudentAnnotation(title: (student.firstName + " " + student.lastName) , subtitle: student.mediaURL, url: student.mediaURL, coordinate: CLLocationCoordinate2D(latitude: Double(student.latitude), longitude: Double(student.longitude)))
			mapView.addAnnotation(annotation)
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
		
		studentTabBar = tabBarController as! StudentTabBarController
		
		addReachability()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		guard appDelegate.sessionId != nil else {
			let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
			studentTabBar.students.removeAllStudents()
			NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
			NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
			presentViewController(loginViewController, animated: true, completion: nil)
			
			return
		}
		
		if reachability!.isReachable() == false {
			if studentTabBar.students.getStudentCount() > 0 {
				updateLocations(nil)
				return
			}
			
			return
		}
		
		self.loadingView.hidden = true
		self.activityIndicatorView.stopAnimating()
		UIApplication.sharedApplication().endIgnoringInteractionEvents()
		
		HttpClient.sharedInstance.getStudentLocations(nil) { (result, error) -> Void in
			if let result = result {
				self.updateLocations(result)
			} else {
				self.studentTabBar.students.removeAllStudents()
				
				performUIUpdatesOnMain {
					if self.activityIndicatorView.isAnimating() {
						self.loadingView.hidden = true
						self.activityIndicatorView.stopAnimating()
					}
					
					if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
						UIApplication.sharedApplication().endIgnoringInteractionEvents()
					}
					
				}
			}
		}
		
	}
}

extension MapViewController : CLLocationManagerDelegate {
	
}

extension MapViewController : MKMapViewDelegate {
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if view.rightCalloutAccessoryView == control {
			let annotation = view.annotation as! StudentAnnotation
			let url = NSURL(string: annotation.url)!
			
			if !UIApplication.sharedApplication().canOpenURL(url) && (!url.absoluteString.hasPrefix("http://") || !url.absoluteString.hasPrefix("https://")) {
				let urlString = "http://" + url.absoluteString
				UIApplication.sharedApplication().openURL(NSURL(string: urlString)!)
			} else {
				UIApplication.sharedApplication().openURL(url)
			}
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