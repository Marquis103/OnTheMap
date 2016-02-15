//
//  UdacityHttpClient.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/8/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

struct UdacityHttpClient {
	
	//implement singleton design pattern
	static let sharedInstance: UdacityHttpClient = UdacityHttpClient()
	
	struct Constants {
		struct UdacityClient {
			static let ApiScheme = "https"
			static let ApiHost = "www.udacity.com"
			static let ApiPath = "/api"
			static let APIMethodUsers = "/users"
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
	
	func getLoginSessionRequest(username: String, password: String) -> NSURLRequest? {
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
	
	func getLogoutSessionRequest() -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.ApiMethod

		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "DELETE"
		var xsrfCookie: NSHTTPCookie? = nil
		let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		for cookie in sharedCookieStorage.cookies! {
			if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
		}
		if let xsrfCookie = xsrfCookie {
			request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
		}
		
		return request
	}
	
	func getStudentDataRequest(username: String) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.APIMethodUsers
		components.query = "/\(username)"
		
		let urlString = components.URL?.absoluteString.stringByReplacingOccurrencesOfString("?", withString: "")
		let request = NSMutableURLRequest(URL: NSURL(string: urlString!)!)
		
		return request
	}
	
	func getFacebookLoginRequest(accessToken: String) -> NSURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.ApiMethod
		
		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = "{\"facebook_mobile\": {\"access_token\": \"\(accessToken)\"}}".dataUsingEncoding(NSUTF8StringEncoding)

		return request
	}
}