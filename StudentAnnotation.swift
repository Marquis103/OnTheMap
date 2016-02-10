//
//  StudentPin.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import MapKit

class StudentAnnotation: NSObject {

	let title:String?
	let subtitle:String?
	let coordinate:CLLocationCoordinate2D
	let url: String
	
	init(title: String?, subtitle: String?, url: String, coordinate: CLLocationCoordinate2D) {
		self.title = title
		self.subtitle = subtitle
		self.coordinate = coordinate
		self.url = url
		
		super.init()
		
	}
}


extension StudentAnnotation : MKAnnotation {
	
}
