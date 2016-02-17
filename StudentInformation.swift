//
//  Student.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/12/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

struct StudentInformation {
	
	var uniqueKey: String
	var firstName: String
	var lastName: String
	var objectId: String
	var mediaURL: String
	var latitude: Float
	var longitude: Float
	var mapString: String
	
	init() {
		firstName = ""
		lastName = ""
		uniqueKey = ""
		mediaURL = ""
		mapString = ""
		objectId = ""
		latitude = 0.00
		longitude = 0.00
	}
	
	init(withName firstName:String, lastName:String) {
		self.firstName = firstName
		self.lastName = lastName
		
		//initialize other variables to default values
		uniqueKey = ""
		mediaURL = ""
		mapString = ""
		objectId = ""
		latitude = 0.00
		longitude = 0.00
	}
	
	init (withUserDetails details:[String:AnyObject]) {
		firstName = details["firstName"] as! String
		lastName = details["lastName"] as! String
		uniqueKey = details["uniqueKey"] as! String
		mediaURL = details["mediaURL"] as! String
		mapString = details["mapString"] as! String
		objectId = details["objectId"] as! String
		latitude = details["latitude"] as! Float
		longitude = details["longitude"] as! Float
	}
	
	static func getBasicStudent(withJSONData data:[String:AnyObject]) -> StudentInformation {
		let user = data["user"]
		
		var student = StudentInformation()
		
		student.firstName = (user!["first_name"] as? String)!
		student.lastName = (user!["last_name"] as? String)!
		student.uniqueKey = (user!["email"]!!["address"] as? String)!
		
		return student
	}
}


