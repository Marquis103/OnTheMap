//
//  ListViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/14/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	weak var appDelegate:AppDelegate!
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		loadingView = UIHelper.activityIndicatorViewLoadingView(self.view.center)
		loadingView.hidden = true
		
		activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
		activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2);
		loadingView.addSubview(activityIndicatorView)
		view.addSubview(loadingView!)
		activityIndicatorView.hidesWhenStopped = true
		activityIndicatorView.activityIndicatorViewStyle = .WhiteLarge
	}
	
	override func viewWillAppear(animated: Bool) {
		guard appDelegate.sessionId != nil else {
			let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
			self.appDelegate.locations?.removeAll()
			NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
			NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
			presentViewController(loginViewController, animated: true, completion: nil)
			
			return
		}
		
		guard let request = ParseHttpClient.sharedInstance.getStudentLocations(nil) else {
			print("Unable to retrieve student locations")
			return
		}
		
		updateLocations(withRequest: request)
	}
	
	@IBAction func refreshLocations(sender: UIBarButtonItem) {
		guard let request = ParseHttpClient.sharedInstance.getStudentLocations(nil) else {
			print("Unable to retrieve student locations")
			return
		}
		
		loadingView.hidden = false
		activityIndicatorView.startAnimating()
		UIApplication.sharedApplication().beginIgnoringInteractionEvents()
		
		//clear current pins
		appDelegate.locations?.removeAll()
		
		updateLocations(withRequest: request)
	}
	
	@IBAction func addNewLocation(sender: UIBarButtonItem) {
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
					self.appDelegate.locations = nil
					return
				}
				
				NSUserDefaults.standardUserDefaults().setValue(results, forKey: "locations")
				self.appDelegate.locations = results
				performUIUpdatesOnMain {
					if self.activityIndicatorView.isAnimating() {
						self.loadingView.hidden = true
						self.activityIndicatorView.stopAnimating()
					}
					
					if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
						UIApplication.sharedApplication().endIgnoringInteractionEvents()
					}
					self.tableView.reloadData()
				}
			}
			
			task.resume()
		} else {
			if let _ = self.appDelegate.locations {
				if self.activityIndicatorView.isAnimating() {
					self.loadingView.hidden = true
					self.activityIndicatorView.stopAnimating()
				}
				
				if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
					UIApplication.sharedApplication().endIgnoringInteractionEvents()
				}

				tableView.reloadData()
			}
		}
	}
}

extension ListViewController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let locations = self.appDelegate.locations {
			let location = locations[indexPath.row]
			let url = NSURL(string: location["mediaURL"] as! String)!
			if !UIApplication.sharedApplication().canOpenURL(url) && (!url.absoluteString.hasPrefix("http://") || !url.absoluteString.hasPrefix("https://")) {
				let urlString = "http://" + url.absoluteString
				UIApplication.sharedApplication().openURL(NSURL(string: urlString)!)
			} else {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}
}

extension ListViewController : UITableViewDataSource {
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("locationsViewCell", forIndexPath: indexPath) as UITableViewCell
		
		if let locations = self.appDelegate.locations {
			let location = locations[indexPath.row]
			
			cell.imageView?.image = UIImage(named: "pin_icon")
			cell.textLabel?.text = (location["firstName"] ?? "") as! String + " " + ((location["lastName"] ?? "") as! String)
		}
		
		return cell
		
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let locations = appDelegate.locations {
			return locations.count
		} else {
			return 0
		}
	}
}
