//
//  ParseHttpClient.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

struct ParseHttpClient {
	
	//implement singleton design pattern
	static let sharedInstance: ParseHttpClient = ParseHttpClient()
	
	struct Constants {
		struct ParseClient {
			static let ApiScheme = "https"
			static let ApiHost = "api.parse.com"
			static let ApiMethod = "/1/classes/StudentLocation"
		}
		
		struct ParseResponseKeys {
			static let results = "results"
		}
	}
	
	func getStudentLocations(parameters: [String:AnyObject]?) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.ParseClient.ApiScheme
		components.host = Constants.ParseClient.ApiHost
		components.path = Constants.ParseClient.ApiMethod
		
		if let parameters = parameters {
			for (key, value) in parameters {
				let queryItem = NSURLQueryItem(name: key, value: "\(value)")
				components.queryItems!.append(queryItem)
			}
		}
		
		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "GET"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		
		return request
	}
}