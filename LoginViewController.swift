//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/7/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController {

	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	weak var appDelegate: AppDelegate!
	var activityIndicatorView:UIActivityIndicatorView!
	var loadingView:UIView!
	var fbLoginButton = FBSDKLoginButton()
	var buttonWidth: CGFloat!
	
	@IBOutlet weak var scrollView: UIScrollView!
	
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
		buttonWidth = view.bounds.width * 0.373
		
		if (toInterfaceOrientation == .LandscapeLeft || toInterfaceOrientation == .LandscapeRight) && view.traitCollection.horizontalSizeClass.rawValue == 1 {
			fbLoginButton.frame = CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 20, width: buttonWidth, height: 30)
		} else {
			fbLoginButton.frame = CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30)
		}
		
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
	
	func keyboardWillShow(notification:NSNotification) {
		if view.frame.origin.y == 0 {
			if usernameTextField.isFirstResponder() {
				let userInfo = notification.userInfo
				let keyboardSize = userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue
				let contentInsets:UIEdgeInsets  = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.CGRectValue().height, 0.0)
				scrollView.contentInset = contentInsets
				scrollView.scrollIndicatorInsets = contentInsets
    
				var aRect: CGRect = view.frame
				aRect.size.height -= keyboardSize.CGRectValue().height
				
				//you may not need to scroll, see if the active field is already visible
				if (!CGRectContainsPoint(aRect, usernameTextField.frame.origin) ) {
					let scrollPoint:CGPoint = CGPointMake(0.0, usernameTextField.frame.origin.y - keyboardSize.CGRectValue().height)
					scrollView.setContentOffset(scrollPoint, animated: true)
				}
			} else if passwordTextField.isFirstResponder() {
				let userInfo = notification.userInfo
				let keyboardSize = userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue
				let contentInsets:UIEdgeInsets  = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.CGRectValue().height, 0.0)
				scrollView.contentInset = contentInsets
				scrollView.scrollIndicatorInsets = contentInsets
    
				var aRect: CGRect = view.frame
				aRect.size.height -= keyboardSize.CGRectValue().height
				
				//you may not need to scroll, see if the active field is already visible
				if (!CGRectContainsPoint(aRect, passwordTextField.frame.origin) ) {
					let scrollPoint:CGPoint = CGPointMake(0.0, passwordTextField.frame.origin.y - keyboardSize.CGRectValue().height)
					scrollView.setContentOffset(scrollPoint, animated: true)
				}
			}
		}
	}
	
	func keyboardWillHide(notification:NSNotification) {
		let contentInsets:UIEdgeInsets = UIEdgeInsetsZero
		scrollView.contentInset = contentInsets
		scrollView.scrollIndicatorInsets = contentInsets
	}
	
	//MARK: View Controller functions
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if let uniqueId = NSUserDefaults.standardUserDefaults().stringForKey("uniqueId") {
			appDelegate.uniqueId = appDelegate.uniqueId ?? uniqueId
		}
		
		if let studentData = NSUserDefaults.standardUserDefaults().objectForKey("student") as? NSData {
			let student = NSKeyedUnarchiver.unarchiveObjectWithData(studentData) as! Student
			appDelegate.student = appDelegate.student ?? student
		}
		
		if let sessionId = NSUserDefaults.standardUserDefaults().stringForKey("sessionId") {
			appDelegate.sessionId = appDelegate.sessionId ?? sessionId
		
			segueLoggedInUser()
		}
		
		//subscribe to keyboard will show notification
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		view.endEditing(true)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		buttonWidth = view.bounds.width * 0.45
		fbLoginButton.frame = CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30)
		fbLoginButton.readPermissions = ["public_profile", "email"]
		fbLoginButton.delegate = self
		
		//add scrollview for moving textfield up from keyboard height
		scrollView.scrollEnabled = true
		scrollView.contentSize = view.frame.size
		scrollView.addSubview(fbLoginButton)
		
		//added loading view for activity indicator
		loadingView = UIHelper.activityIndicatorViewLoadingView(self.view.center)
		loadingView.hidden = true
		activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
		activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2);
		loadingView.addSubview(activityIndicatorView)
		view.addSubview(loadingView!)
		activityIndicatorView.hidesWhenStopped = true
		activityIndicatorView.activityIndicatorViewStyle = .WhiteLarge

		//create background gradient
		backgroundGradient = CAGradientLayer().orangeColor()
		backgroundGradient.frame = view.bounds
		
		//view.addSubview(scrollView)
		setUpTextFields()
		
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
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
			
			if let studentRequest = UdacityHttpClient.sharedInstance.getStudentDataRequest(self.usernameTextField.text!) {
				let userTask = self.appDelegate.sharedSession.dataTaskWithRequest(studentRequest) { userData, userResponse, userError in
					let (parsedResult, _) = UIHelper.handleStudentDataResponse(userData, response: userResponse, error: userError)
					
					if let parsedResult = parsedResult {
						//build student struct and save it
						let student = UIHelper.getStudent(parsedResult)
						
						self.appDelegate.student = student
						let data = NSKeyedArchiver.archivedDataWithRootObject(student)
						NSUserDefaults.standardUserDefaults().setObject(data, forKey: "student")
					}
				}
				
				userTask.resume()
			}
			
			
			//userTask.resume()
			
			self.appDelegate.sessionId = sessionToken
			self.appDelegate.uniqueId = self.usernameTextField.text
			
			NSUserDefaults.standardUserDefaults().setValue(sessionToken, forKey: "sessionId")
			NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.uniqueId, forKey: "uniqueId")
			
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

extension LoginViewController : FBSDKLoginButtonDelegate {
	func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
		FBSDKAccessToken.setCurrentAccessToken(nil)
	}
	
	func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
		guard error == nil else {
			userAlert("Login Error", message: "Unable to authenticate using Facebook!")
			return
		}
		
		//get facebook details
		let graph = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"])
		graph.startWithCompletionHandler { (connection, result, error) -> Void in
			guard error == nil else {
				print(error)
				performUIUpdatesOnMain {
					self.userAlert("Login Error", message: "Unable to authenticate using Facebook!")
				}
				
				return
			}
			
			//self.appDelegate.accessToken = FBSDKAccessToken.currentAccessToken()
			
			guard let request = UdacityHttpClient.sharedInstance.getFacebookLoginRequest(FBSDKAccessToken.currentAccessToken().tokenString) else {
				self.userAlert("Login Failure", message: "Could not generate facebook request")
				return
			}
			
			let task = self.appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
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
				
				if let studentRequest = UdacityHttpClient.sharedInstance.getStudentDataRequest(result["email"] as! String) {
					let userTask = self.appDelegate.sharedSession.dataTaskWithRequest(studentRequest) { userData, userResponse, userError in
						let (parsedResult, _) = UIHelper.handleStudentDataResponse(userData, response: userResponse, error: userError)
						
						if let parsedResult = parsedResult {
							//build student struct and save it
							let student = UIHelper.getStudent(parsedResult)
							
							self.appDelegate.student = student
							let data = NSKeyedArchiver.archivedDataWithRootObject(student)
							NSUserDefaults.standardUserDefaults().setObject(data, forKey: "student")
						}
					}
					
					userTask.resume()
				}
				
				self.appDelegate.sessionId = sessionToken
				self.appDelegate.uniqueId = result["email"] as? String
				
				NSUserDefaults.standardUserDefaults().setValue(sessionToken, forKey: "sessionId")
				NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.uniqueId, forKey: "uniqueId")
				
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
	}
}

extension UIScrollView {
	public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		super.touchesBegan(touches, withEvent: event)
		nextResponder()?.touchesBegan(touches, withEvent: event)
	}
}