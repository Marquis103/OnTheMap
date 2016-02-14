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
	
	func getStudentLocation(uniqueKey:String) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.ParseClient.ApiScheme
		components.host = Constants.ParseClient.ApiHost
		components.path = Constants.ParseClient.ApiMethod
		
		components.query = "where={\"uniqueKey\":\"\(uniqueKey)\"}"
		
		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "GET"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		
		return request
	}
	
	private func emptyString() -> String {
		return ""
	}
	
	func postStudentLocation(parameters: [String:AnyObject]) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.ParseClient.ApiScheme
		components.host = Constants.ParseClient.ApiHost
		components.path = Constants.ParseClient.ApiMethod
		
		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "POST"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let httpBody = "{\"uniqueKey\": \"\(parameters["uniqueKey"] ?? emptyString())\", \"firstName\": \"\(parameters["firstName"] ?? emptyString())\", \"lastName\": \"\(parameters["lastName"] ?? emptyString())\",\"mapString\": \"\(parameters["mapString"] ?? emptyString())\", \"mediaURL\": \"\(parameters["mediaURL"] ?? emptyString())\",\"latitude\": \(parameters["latitude"]!), \"longitude\": \(parameters["longitude"]!)}"
		request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
		
		return request
	}

	func updateStudentLocation(parameters: [String:AnyObject], objectId:String) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.ParseClient.ApiScheme
		components.host = Constants.ParseClient.ApiHost
		components.path = Constants.ParseClient.ApiMethod
		
		components.query = "/\(objectId)"
		
		let urlString = components.URL?.absoluteString.stringByReplacingOccurrencesOfString("?", withString: "")
		let request = NSMutableURLRequest(URL: NSURL(string: urlString!)!)
		
		request.HTTPMethod = "PUT"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		let httpBody = "{\"uniqueKey\": \"\(parameters["uniqueKey"] ?? emptyString())\", \"firstName\": \"\(parameters["firstName"] ?? emptyString())\", \"lastName\": \"\(parameters["lastName"] ?? emptyString())\",\"mapString\": \"\(parameters["mapString"] ?? emptyString())\", \"mediaURL\": \"\(parameters["mediaURL"] ?? emptyString())\",\"latitude\": \(parameters["latitude"]!), \"longitude\": \(parameters["longitude"]!)}"
		
		request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
		
		return request
	}
}