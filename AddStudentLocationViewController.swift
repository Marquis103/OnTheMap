//
//  AddStudentLocationViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/10/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit

class AddStudentLocationViewController: UIViewController {
	
	@IBOutlet weak var topView: UIView!
	@IBOutlet weak var bottomView: UIView!
	@IBOutlet weak var btnSubmit: UIButton!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var locationTextField: UITextField!
	@IBOutlet weak var cancelBarButton: UIBarButtonItem!
	@IBOutlet weak var linkTextField: UITextField!
	
	var isMapVisible = false
	var btnAddLocation:UIButton!
	weak var appDelegate:AppDelegate!
	
	private var buttonWidth:CGFloat!
	var locationRequest:NSURLRequest?
	
	//MARK: Functions
	func postStudentLocation() {
		if let annotation = mapView.annotations.first, student = appDelegate.student {
			//is the request an update or a new post
			var update = false
			
			var queryParameters = [String:AnyObject]()
			
			queryParameters["uniqueKey"] = appDelegate.uniqueId
			queryParameters["mediaURL"] = linkTextField.text ?? ""
			queryParameters["firstName"] = student.firstName
			queryParameters["lastName"] = student.lastName
			queryParameters["mapString"] = locationTextField.text ?? ""
			queryParameters["latitude"] = annotation.coordinate.latitude
			queryParameters["longitude"] = annotation.coordinate.longitude
			
			if let objectId = appDelegate.student?.objectId {
				guard let request = ParseHttpClient.sharedInstance.updateStudentLocation(queryParameters, objectId: objectId) else {
					userAlert("Post Error", message: "There was an posting location")
					return
				}
				
				update = true
				locationRequest = request
			} else {
				guard let request = ParseHttpClient.sharedInstance.postStudentLocation(queryParameters) else {
					userAlert("Post Error", message: "There was an posting location")
					return
				}
				
				locationRequest = request
			}
			
			let task = appDelegate.sharedSession.dataTaskWithRequest(locationRequest!) {data, response, error in
				if !update {
					let (parsedResult, error) = UIHelper.handleStudentDataResponse(data, response: response, error: error)
					
					guard error == nil else {
						performUIUpdatesOnMain {
							self.userAlert("Post Error", message: "There was an error posting location")
						}
						
						return
					}
					
					//set objectId if necessary
					if self.appDelegate.student?.objectId == nil {
						if let objectId = parsedResult!["objectId"] as? String {
							self.appDelegate.student?.objectId = objectId
							let data = NSKeyedArchiver.archivedDataWithRootObject(self.appDelegate.student!)
							NSUserDefaults.standardUserDefaults().setObject(data, forKey: "student")
						}
					}
				}
				
				performUIUpdatesOnMain {
					let tabBarController = self.storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
					self.presentViewController(tabBarController, animated: true, completion: nil)
				}
			}
			
			task.resume()
		}
	}
		
	
	//MARK: Lifecycle Methods
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		locationTextField.contentVerticalAlignment = .Top
		linkTextField.contentVerticalAlignment = .Center
		btnSubmit.layer.cornerRadius = 10
		
		buttonWidth = view.bounds.width * 0.373
		btnAddLocation = UIButton(frame: CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30))
		btnAddLocation.setTitle("Submit", forState: .Normal)
		btnAddLocation.setTitleColor(UIColor(red: 40/255.0, green: 107/255.0, blue: 167/255.0, alpha: 1), forState: .Normal)
		btnAddLocation.backgroundColor = UIColor.whiteColor()
		btnAddLocation.layer.cornerRadius = 10
		btnAddLocation.addTarget(self, action: "postStudentLocation", forControlEvents: .TouchUpInside)
		view.addSubview(btnAddLocation)
		
		btnAddLocation.hidden = true
		
		locationTextField.delegate = self
		linkTextField.delegate = self
		
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		view.endEditing(true)
	}
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		buttonWidth = view.bounds.width * 0.373
		btnAddLocation.frame = CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30)
	}
	
	func userAlert(title:String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(alertAction)
		
		performUIUpdatesOnMain {
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	//MARK: Actions
	
	@IBAction func cancelLocationAdd(sender: AnyObject) {
		if isMapVisible {
			isMapVisible = !isMapVisible
			
			topView.hidden = false
			bottomView.hidden = false
			btnAddLocation.hidden = true
			cancelBarButton.tintColor  = nil
			locationTextField.hidden = false
			navigationController?.navigationBar.barTintColor = nil
		} else {
			let tabBarController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
			presentViewController(tabBarController, animated: true, completion: nil)
		}
		
	}
	@IBAction func submitLocation(sender: UIButton) {
		guard let address = locationTextField.text where locationTextField.text != "" else {
			userAlert("Location not found", message: "Please ensure you have entered a valid location!")
			return
		}
		
		isMapVisible = !isMapVisible
		
		topView.hidden = true
		bottomView.hidden = true
		btnAddLocation.hidden = false
		cancelBarButton.tintColor  = UIColor.whiteColor()
		locationTextField.hidden = true
		navigationController?.navigationBar.barTintColor = UIColor(red: 27/255.0, green: 109/255.0, blue: 168/255.0, alpha: 0.5)
		
		let geoCoder = CLGeocoder()
		geoCoder.geocodeAddressString(address) { (placemarks, error) -> Void in
			guard error == nil else {
				performUIUpdatesOnMain {
					self.userAlert("Location not found", message: "Please ensure you have entered a valid location")
				}
				
				return
			}
			
			if let placemark = placemarks?.first {
				let annotation = MKPlacemark(placemark: placemark)
				
				let latDelta:CLLocationDegrees = 0.01
				let longDelta:CLLocationDegrees = 0.01
				
				let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
				let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
				
				self.mapView.setRegion(region, animated: true)
				
				self.mapView.addAnnotation(annotation)
				
			}
		}
	}
}

extension AddStudentLocationViewController : UITextFieldDelegate {
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
