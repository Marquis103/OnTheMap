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
			self.presentViewController(alert, animated: true, completion: nil)
		}
		
	}
	
	func setUpTextFields() {
		let attributedUsernameString = NSAttributedString(string: "  Username", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		let attributedPasswordString = NSAttributedString(string: "  Password", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		usernameTextField.attributedPlaceholder = attributedUsernameString
		passwordTextField.attributedPlaceholder = attributedPasswordString
	}
	
	func segueToMap() {
		print("We have segued")
		print(appDelegate.sessionId)
	}

	func unsuccessfulLogin() {
		userAlert("Login unsuccessful", message: "Login credentials were not accepted")
	}
	
	//MARK: View Controller functions
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if let sessionId = NSUserDefaults.standardUserDefaults().stringForKey("sessionID") {
			if let _ = appDelegate.sessionId {
				segueToMap()
			} else {
				appDelegate.sessionId = sessionId
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		
		backgroundGradient = CAGradientLayer().orangeColor()
		
		setUpTextFields()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "segueToMap", name: "UdacitySessionSetNotification", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "unsuccessfulLogin", name: "UdacityUnsuccessfulLoginNotification", object: nil)
		
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	//MARK: Actions
	@IBAction func loginUser(sender: UIButton) {
		guard let username = usernameTextField.text, password = passwordTextField.text
			where username != "" && password != "" else {
			userAlert("Login Error", message: "Username and Password are required to login!")
			return
		}
		
		UdacityHTTPClient.sharedInstance.getUdacitySession(username, password: password)
	}
}

extension LoginViewController : UITextFieldDelegate {
	func textFieldDidBeginEditing(textField: UITextField) {
		if textField.text == "  Username" || textField.text == "  Password" {
			textField.text = ""
		}
	}
}