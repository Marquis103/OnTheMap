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
	
	
	var backgroundGradient: CAGradientLayer! {
		didSet {
			backgroundGradient.frame = view.bounds
			view.layer.insertSublayer(backgroundGradient, atIndex: 0)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		backgroundGradient = CAGradientLayer().orangeColor()
		
		
		let attributedUsernameString = NSAttributedString(string: "  Username", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		let attributedPasswordString = NSAttributedString(string: "  Password", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
		usernameTextField.attributedPlaceholder = attributedUsernameString
		passwordTextField.attributedPlaceholder = attributedPasswordString
	}
}
