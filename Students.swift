//
//  Students.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/17/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

struct Students {
	private var students = [StudentInformation]()
	
	init(initWithStudentJsonData data:[[String:AnyObject]]) {
		for (_, student) in data.enumerate() {
			students.append(StudentInformation(withUserDetails: student))
		}
	}
	
	func getStudents() -> [StudentInformation] {
		return students
	}
}