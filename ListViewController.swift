//
//  ListViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/14/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import ReachabilitySwift

class ListViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	weak var appDelegate:AppDelegate!
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	var reachability:Reachability?
	
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
		
		addReachability()
	}
	
	override func viewWillAppear(animated: Bool) {
		guard appDelegate.sessionId != nil else {
			let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
			self.appDelegate.students?.removeAll()
			NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
			NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
			presentViewController(loginViewController, animated: true, completion: nil)
			
			return
		}
		
		if reachability!.isReachable() == false {
			if let _ = self.appDelegate.students {
				updateLocations(nil)
				return
			}
			
			return
		}
		
		var parameters = [String:AnyObject]()
		parameters["order"] = "-updatedAt"
		
		HttpClient.sharedInstance.getStudentLocations(parameters) { (result, error) -> Void in
			if let result = result {
				self.updateLocations(result)
			} else {
				self.appDelegate.students = nil
			}
		}
	}
	
	@IBAction func refreshLocations(sender: UIBarButtonItem) {
		if reachability!.isReachable() == false {
			userAlert("Refresh Failed", message: "Internet connection available to refresh")
			return
		}
		
		var parameters = [String:AnyObject]()
		parameters["order"] = "-updatedAt"
		
		HttpClient.sharedInstance.getStudentLocations(parameters) { (result, error) -> Void in
			self.loadingView.hidden = false
			self.activityIndicatorView.startAnimating()
			UIApplication.sharedApplication().beginIgnoringInteractionEvents()
			
			guard error == nil else {
				self.userAlert("Could Not Refresh", message: (error?.userInfo["NSLocalizedDescriptionKey"]!)! as! String)
				return
			}
			
			if let result = result {
				//clear current pins
				self.appDelegate.students?.removeAll()
				self.updateLocations(result)
			} else {
				self.appDelegate.students = nil
			}
		}
	}
	
	
	@IBAction func logUserOut(sender: UIBarButtonItem) {
		let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		self.appDelegate.students?.removeAll()
		appDelegate.sessionId = nil
		NSUserDefaults.standardUserDefaults().removeObjectForKey("locations")
		NSUserDefaults.standardUserDefaults().removeObjectForKey("sessionId")
		NSUserDefaults.standardUserDefaults().removeObjectForKey("uniqueId")
		
		FBSDKAccessToken.setCurrentAccessToken(nil)
		
		HttpClient.sharedInstance.getUdacityLogoutSession(nil) { (result, error) -> Void in
			guard error == nil else {
				return
			}
			
			performUIUpdatesOnMain {
				self.presentViewController(loginViewController, animated: true, completion: nil)
			}
		}
	}

	
	@IBAction func addNewLocation(sender: UIBarButtonItem) {
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
					self.appDelegate.students = nil
					
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
		reachability!.stopNotifier()
	}
	
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
			let results = parsedResult! [HttpClient.Constants.ParseResponseKeys.results] as? [[String:AnyObject]]
			
			NSUserDefaults.standardUserDefaults().setValue(results, forKey: "locations")
			
			appDelegate.students = Students(initWithStudentJsonData: results!).getStudents()
		}
		
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
}

extension ListViewController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let students = self.appDelegate.students {
			let student = students[indexPath.row]
			let url = NSURL(string: student.mediaURL)!
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
		
		if let students = self.appDelegate.students {
			let student = students[indexPath.row]
			
			cell.imageView?.image = UIImage(named: "pin_icon")
			cell.textLabel?.text = student.firstName + " " + student.lastName
		}
		
		return cell
		
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let students = appDelegate.students {
			return students.count
		} else {
			return 0
		}
	}
}
