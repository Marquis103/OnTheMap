//
//  Student.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/12/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

class Student : NSObject, NSCoding {
	
	var uniqueKey: String
	var firstName: String
	var lastName: String
	var objectId: String?
	
	init(firstName: String, lastName:String, uniqueKey: String, objectId: String?) {
		self.firstName = firstName
		self.lastName = lastName
		self.uniqueKey = uniqueKey
	}
	
	convenience required init?(coder aDecoder: NSCoder) {
		guard let uniqueKey = aDecoder.decodeObjectForKey("uniqueKey") as? String,
			let firstName = aDecoder.decodeObjectForKey("lastName") as? String,
			let lastName = aDecoder.decodeObjectForKey("lastName") as? String
			else {
				return nil
		}
		
		let objectId = aDecoder.decodeObjectForKey("objectId") as? String
		
		self.init(firstName: firstName, lastName: lastName, uniqueKey: uniqueKey, objectId: objectId)
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(self.uniqueKey, forKey: "uniqueKey")
		aCoder.encodeObject(self.firstName, forKey: "firstName")
		aCoder.encodeObject(self.lastName, forKey: "lastName")
		if let objectId = self.objectId {
			aCoder.encodeObject(objectId, forKey: "objectId")
		}
	}
}


