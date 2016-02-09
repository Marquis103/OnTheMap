//
//  UdacityHTTPClient.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/8/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

struct UdacityHTTPClient {
	
	//implement singleton design pattern
	static let sharedInstance: UdacityHTTPClient = UdacityHTTPClient()
	
	struct Constants {
		struct UdacityClient {
			static let ApiScheme = "https"
			static let ApiHost = "www.udacity.com"
			static let ApiPath = "/api"
			static let ApiMethod = "/session"
		}
		
		struct ParameterKeys {
			static let username = "username"
			static let password = "password"
		}
		
		struct UdacityResponseKeys {
			static let session = "session"
			static let session_id = "id"
		}
	}
	
	func getUdacitySessionRequest(username: String, password: String) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.ApiMethod

		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
		
		return request
	}
}