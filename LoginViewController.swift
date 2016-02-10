//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/7/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	var appDelegate: AppDelegate!
	var activityIndicatorView:UIActivityIndicatorView!
	
	//MARK: UI Functions
	var backgroundGradient: CAGradientLayer! {
		didSet {
			backgroundGradient.frame = view.bounds
			view.layer.insertSublayer(backgroundGradient, atIndex: 0)
		}
	}
	
	func userAlert(title:String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(alertAction)
		
		performUIUpdatesOnMain {
			if self.activityIndicatorView.isAnimating() {
				self.activityIndicatorView.stopAnimating()
			}
			
			if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
				UIApplication.sharedApplication().endIgnoringInteractionEvents()
			}
			
			self.presentViewController(alert, animated: true, completion: nil)
		}
		
	}
	
	func setUpTextFields() {
		let attributedUsernameString = NSAttributedString(string: "  Username", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		let attributedPasswordString = NSAttributedString(string: "  Password", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		usernameTextField.attributedPlaceholder = attributedUsernameString
		passwordTextField.attributedPlaceholder = attributedPasswordString
	}
	
	func segueLoggedInUser() {
		performUIUpdatesOnMain {
			self.performSegueWithIdentifier("loggedInUser", sender: nil)
		}
	}

	func unsuccessfulLogin() {
		userAlert("Login unsuccessful", message: "Login credentials were not accepted")
	}
	
	//MARK: View Controller functions
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if let sessionId = NSUserDefaults.standardUserDefaults().stringForKey("sessionId") {
			if let _ = appDelegate.sessionId {
				appDelegate.sessionId = sessionId
			}
		
			segueLoggedInUser()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
		activityIndicatorView.center = view.center
		activityIndicatorView.hidesWhenStopped = true
		activityIndicatorView.activityIndicatorViewStyle = .Gray
		view.addSubview(activityIndicatorView)
		
		backgroundGradient = CAGradientLayer().orangeColor()
		
		setUpTextFields()
		
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	//MARK: Actions
	@IBAction func loginUser(sender: UIButton) {
		activityIndicatorView.startAnimating()
		UIApplication.sharedApplication().beginIgnoringInteractionEvents()
		
		guard let username = usernameTextField.text, password = passwordTextField.text
			where username != "" && password != "" else {
			userAlert("Login Error", message: "Username and Password are required to login!")
			return
		}
		
		guard let request = UdacityHttpClient.sharedInstance.getLoginSessionRequest(username, password: password) else {
			userAlert("Login Error", message: "Login was unsuccessful, please try again!")
			return
		}
		
		
		let task = appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
			
			let (parsedResult, error) = UIHelper.handleNSURLSessionLoginResponse(data, response: response, error: error)
			
			guard (error == nil) else {
				self.userAlert("Login Unsuccessful", message: (error?.domain)!)
				return
				
			}
			
			//is the session token in the parsed results
			guard let sessionToken = parsedResult![UdacityHttpClient.Constants.UdacityResponseKeys.session]!![UdacityHttpClient.Constants.UdacityResponseKeys.session_id] as? String else {
				self.userAlert("Login Unsuccessful", message: "Could not locate session id")
				return
			}
			
			self.appDelegate.sessionId = sessionToken
			NSUserDefaults.standardUserDefaults().setValue(sessionToken, forKey: "sessionId")
			
			performUIUpdatesOnMain {
				if self.activityIndicatorView.isAnimating() {
					self.activityIndicatorView.stopAnimating()
				}
				
				self.segueLoggedInUser()
			}
			
		}
		
		task.resume()
	}
}

extension LoginViewController : UITextFieldDelegate {
	func textFieldDidBeginEditing(textField: UITextField) {
		if textField.text == "  Username" || textField.text == "  Password" {
			textField.text = ""
		}
	}
}