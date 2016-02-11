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
	var loadingView:UIView!
	
	//MARK: UI Functions
	var backgroundGradient: CAGradientLayer! {
		didSet {
			view.layer.insertSublayer(backgroundGradient, atIndex: 0)
		}
	}
	
	func userAlert(title:String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(alertAction)
		
		performUIUpdatesOnMain {
			if self.activityIndicatorView.isAnimating() {
				self.loadingView.hidden = true
				self.activityIndicatorView.stopAnimating()
			}
			
			if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
				UIApplication.sharedApplication().endIgnoringInteractionEvents()
			}
			
			self.presentViewController(alert, animated: true, completion: nil)
		}
		
	}
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		backgroundGradient.frame = view.bounds
		loadingView.center = view.center
		activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2);
	}
	
	func setUpTextFields() {
		let attributedUsernameString = NSAttributedString(string: "  Username", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		let attributedPasswordString = NSAttributedString(string: "  Password", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		
		usernameTextField.attributedPlaceholder = attributedUsernameString
		passwordTextField.attributedPlaceholder = attributedPasswordString
		
		usernameTextField.delegate = self
		passwordTextField.delegate = self
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
			appDelegate.sessionId = appDelegate.sessionId ?? sessionId
		
			segueLoggedInUser()
		}
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		view.endEditing(true)
	}
	
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
		
		backgroundGradient = CAGradientLayer().orangeColor()
		backgroundGradient.frame = view.bounds
		
		setUpTextFields()
		
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	//MARK: Actions
	@IBAction func loginUser(sender: UIButton) {
		loadingView.hidden = false
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
					self.loadingView.hidden = true
					self.activityIndicatorView.stopAnimating()
				}
				
				self.segueLoggedInUser()
			}
			
		}
		
		task.resume()
	}
	
	@IBAction func goToSignUpAtUdacity(sender: UIButton) {
		UIApplication.sharedApplication().openURL(NSURL(string: "https://www.udacity.com/account/auth#!/signin")!)
	}
	
	
}

extension LoginViewController : UITextFieldDelegate {
	func textFieldDidBeginEditing(textField: UITextField) {
		if textField.attributedPlaceholder?.string == "  Username" || textField.attributedPlaceholder?.string == "  Password" {
			textField.attributedPlaceholder = nil
		}
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}