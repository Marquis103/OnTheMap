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
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	private var buttonWidth:CGFloat!
	var locationRequest:NSURLRequest?
	
	//MARK: Functions
	func postStudentLocation() {
		if let annotation = mapView.annotations.first, student = appDelegate.currentStudent {
			
			var queryParameters = [String:AnyObject]()
			
			queryParameters["uniqueKey"] = appDelegate.uniqueId
			queryParameters["mediaURL"] = linkTextField.text ?? ""
			queryParameters["firstName"] = student.firstName
			queryParameters["lastName"] = student.lastName
			queryParameters["mapString"] = locationTextField.text ?? ""
			queryParameters["latitude"] = annotation.coordinate.latitude
			queryParameters["longitude"] = annotation.coordinate.longitude
			
			
			if let objectId = appDelegate.currentStudent?.objectId where appDelegate.currentStudent?.objectId != "" {
				HttpClient.sharedInstance.updateStudentLocation(queryParameters, objectId: objectId, completionHandler: { (result, error) -> Void in
					guard error == nil else {
						self.userAlert("Post Error", message: (error?.userInfo["NSLocalizedDescriptionKey"]!)! as! String)
						return
					}
					
					
					//update currentStudent
					self.appDelegate.currentStudent?.uniqueKey = queryParameters["uniqueKey"] as! String
					self.appDelegate.currentStudent?.mediaURL = queryParameters["mediaURL"] as! String
					self.appDelegate.currentStudent?.mapString = queryParameters["mapString"] as! String
					self.appDelegate.currentStudent?.latitude = queryParameters["latitude"] as! Float
					self.appDelegate.currentStudent?.longitude = queryParameters["longitude"] as! Float
					
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("showMapSegue", sender: nil)
					}
				})
				
			} else {
				HttpClient.sharedInstance.postStudentLocation(queryParameters, completionHandler: { (result, error) -> Void in
					guard error == nil else {
						self.userAlert("Post Error", message: (error?.userInfo["NSLocalizedDescriptionKey"]!)! as! String)
						return
					}
					
					//set objectId if necessary
					if self.appDelegate.currentStudent?.objectId == nil {
						if let objectId = result!["objectId"] as? String {
							self.appDelegate.currentStudent?.objectId = objectId
						}
					}
					
					//update currentStudent
					self.appDelegate.currentStudent?.uniqueKey = queryParameters["uniqueKey"] as! String
					self.appDelegate.currentStudent?.mediaURL = queryParameters["mediaURL"] as! String
					self.appDelegate.currentStudent?.mapString = queryParameters["mapString"] as! String
					self.appDelegate.currentStudent?.latitude = queryParameters["latitude"] as! Float
					self.appDelegate.currentStudent?.longitude = queryParameters["longitude"] as! Float
					
					performUIUpdatesOnMain {
						self.performSegueWithIdentifier("showMapSegue", sender: nil)
					}
				})
				
			}
		}
	}
		
	
	//MARK: Lifecycle Methods
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
		
		let attributedLocationString = NSAttributedString(string: "Enter geographical location here!", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		let attributedLinkTextString = NSAttributedString(string: "Enter url for location!", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		
		locationTextField.attributedPlaceholder = attributedLocationString
		linkTextField.attributedPlaceholder = attributedLinkTextString
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
			updateMapUI(isMapVisible)
		} else {
			self.performSegueWithIdentifier("showMapSegue", sender: nil)
		}
		
	}
	
	func updateMapUI(isMapVisible:Bool) {
		if isMapVisible {
			topView.hidden = true
			bottomView.hidden = true
			btnAddLocation.hidden = false
			cancelBarButton.tintColor  = UIColor.whiteColor()
			locationTextField.hidden = true
			navigationController?.navigationBar.barTintColor = UIColor(red: 27/255.0, green: 109/255.0, blue: 168/255.0, alpha: 0.5)
		} else {
			topView.hidden = false
			bottomView.hidden = false
			btnAddLocation.hidden = true
			cancelBarButton.tintColor  = nil
			locationTextField.hidden = false
			navigationController?.navigationBar.barTintColor = nil
		}
	}
	
	@IBAction func submitLocation(sender: UIButton) {
		guard let address = locationTextField.text where locationTextField.text != "" else {
			userAlert("Location not found", message: "Please ensure you have entered a valid location!")
			return
		}
		
		loadingView.hidden = false
		activityIndicatorView.startAnimating()
		UIApplication.sharedApplication().beginIgnoringInteractionEvents()
		
		let geoCoder = CLGeocoder()
		geoCoder.geocodeAddressString(address) { (placemarks, error) -> Void in
			guard error == nil else {
				performUIUpdatesOnMain {
					self.loadingView.hidden = true
					if self.activityIndicatorView.isAnimating() {
						self.activityIndicatorView.startAnimating()
					}
					if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
						UIApplication.sharedApplication().endIgnoringInteractionEvents()
					}
				
					self.userAlert("Location not found", message: "Please ensure you have entered a valid location")
				}
				
				return
			}
			
			self.isMapVisible = !self.isMapVisible
			self.updateMapUI(self.isMapVisible)
			
			
			if let placemark = placemarks?.first {
				let annotation = MKPlacemark(placemark: placemark)
				
				let latDelta:CLLocationDegrees = 0.01
				let longDelta:CLLocationDegrees = 0.01
				
				let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
				let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
				
				self.mapView.setRegion(region, animated: true)
				
				self.mapView.addAnnotation(annotation)
				
				performUIUpdatesOnMain {
					self.loadingView.hidden = true
					self.activityIndicatorView.stopAnimating()
					if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
						UIApplication.sharedApplication().endIgnoringInteractionEvents()
					}
				}
				
			}
		}
	}
}

extension AddStudentLocationViewController : UITextFieldDelegate {
	func textFieldDidBeginEditing(textField: UITextField) {
		
		if textField.attributedPlaceholder?.string == "Enter geographical location here!" || textField.attributedPlaceholder?.string == "Enter url for location!"{
			textField.attributedPlaceholder = nil
		}
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
