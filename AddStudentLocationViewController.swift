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

	private var buttonWidth:CGFloat!
	
	//MARK: Lifecycle Methods
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationTextField.contentVerticalAlignment = .Top
		linkTextField.contentVerticalAlignment = .Center
		btnSubmit.layer.cornerRadius = 10
		
		buttonWidth = view.bounds.width * 0.373
		btnAddLocation = UIButton(frame: CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30))
		btnAddLocation.setTitle("Submit", forState: .Normal)
		btnAddLocation.setTitleColor(UIColor(red: 40/255.0, green: 107/255.0, blue: 167/255.0, alpha: 1), forState: .Normal)
		btnAddLocation.backgroundColor = UIColor.whiteColor()
		btnAddLocation.layer.cornerRadius = 10
		
		view.addSubview(btnAddLocation)
		
		//view.addConstraints([centerLayout, bottomLayout])
		btnAddLocation.hidden = true
		
		let gesture = UITapGestureRecognizer(target: self, action: "printbounds:")
		mapView.addGestureRecognizer(gesture)
	}
	
	func printbounds(gesture: UITapGestureRecognizer) {
		print(gesture.locationInView(view))
	}
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		buttonWidth = view.bounds.width * 0.373
		btnAddLocation.frame = CGRect(x: CGRectGetMidX(view.bounds) - buttonWidth / 2, y: CGRectGetMaxY(view.bounds) - 40, width: buttonWidth, height: 30)
	}
	
	//MARK: Actions
	
	@IBAction func submitLocation(sender: UIButton) {
		isMapVisible = !isMapVisible
		
		if isMapVisible {
			topView.hidden = true
			bottomView.hidden = true
			btnAddLocation.hidden = false
			cancelBarButton.tintColor  = UIColor.whiteColor()
			locationTextField.hidden = true
			navigationController?.navigationBar.barTintColor = UIColor(red: 40/255.0, green: 107/255.0, blue: 167/255.0, alpha: 1)
		}
	}
}
