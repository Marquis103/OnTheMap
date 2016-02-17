//
//  HttpClient.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/16/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

class HttpClient: NSObject {
	weak var appDelegate:AppDelegate!
	
	static let sharedInstance: HttpClient = HttpClient()
	
	// shared session
	var session = NSURLSession.sharedSession()
	
	struct Constants {
		struct UdacityClient {
			static let ApiScheme = "https"
			static let ApiHost = "www.udacity.com"
			static let ApiPath = "/api"
			static let APIMethodUsers = "/users"
			static let ApiMethod = "/session"
		}
		
		struct UdacityParameterKeys {
			static let username = "username"
			static let password = "password"
		}
		
		struct UdacityResponseKeys {
			static let session = "session"
			static let session_id = "id"
		}
		
		struct ParseClient {
			static let ApiScheme = "https"
			static let ApiHost = "api.parse.com"
			static let ApiMethod = "/1/classes/StudentLocation"
		}
		
		struct ParseParameters {
			static let AppID =  "X-Parse-Application-Id"
			static let RestKey = "X-Parse-REST-API-Key"
			static let ContentType = "Content-Type"
		}
		
		struct ParseResponseKeys {
			static let results = "results"
		}
	}
	
	func checkForErrors(data:NSData?, response:NSURLResponse?, error:NSError?) -> NSError? {
		func sendError(error:String) -> NSError {
			print(error)
			let userInfo = [NSLocalizedDescriptionKey : error]
			return NSError(domain: "taskForGetMethod", code: -1, userInfo: userInfo)
		}
		
		//was there an error
		guard (error == nil) else {
			return sendError("There was an error with your request \(error)")
		}
		
		//did we get a successful response from the API?
		guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
			return sendError("There was an error with your request.  Status code is \((response as? NSHTTPURLResponse)?.statusCode)")
		}
		
		//guard was there any data returned
		guard let _ = data else {
			return sendError("Data was not found")
		}
		
		return nil
	}
	
	private func getURLFromParameters(parameters: [String:AnyObject]?, query:String?, replaceQueryString:Bool) -> NSMutableURLRequest {
		let components = NSURLComponents()
		components.scheme = Constants.ParseClient.ApiScheme
		components.host = Constants.ParseClient.ApiHost
		components.path = Constants.ParseClient.ApiMethod
		
		if let query = query {
			components.query = query
		}
		
		if let parameters = parameters {
			var queryItems = [NSURLQueryItem]()
			
			for (key, value) in parameters {
				let queryItem = NSURLQueryItem(name: key, value: "\(value)")
				queryItems.append(queryItem)
			}
			
			components.queryItems = queryItems
		}
		
		if replaceQueryString {
			let urlString = components.URL?.absoluteString.stringByReplacingOccurrencesOfString("?", withString: "")
			return NSMutableURLRequest(URL: NSURL(string: urlString!)!)
		} else {
			return NSMutableURLRequest(URL: components.URL!)
		}
	}
	
	private func getUdacityURLFromParameters(parameters: [String:AnyObject]?, query:String?, replaceQueryString:Bool) -> NSMutableURLRequest {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.ApiMethod
		
		if let query = query {
			components.query = query
		}
		
		if let parameters = parameters {
			var queryItems = [NSURLQueryItem]()
			
			for (key, value) in parameters {
				let queryItem = NSURLQueryItem(name: key, value: "\(value)")
				queryItems.append(queryItem)
			}
			
			components.queryItems = queryItems
		}
		
		if replaceQueryString {
			let urlString = components.URL?.absoluteString.stringByReplacingOccurrencesOfString("?", withString: "")
			return NSMutableURLRequest(URL: NSURL(string: urlString!)!)
		} else {
			return NSMutableURLRequest(URL: components.URL!)
		}
	}
	
	func getUdacityLoginSession(var parameters: [String:AnyObject]?, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getUdacityURLFromParameters(nil, query: nil, replaceQueryString: false)
		
		request.HTTPMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = "{\"udacity\": {\"username\": \"\(parameters!["username"] as! String)\", \"password\": \"\(parameters!["password"] as! String)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				//subset data for udacity api
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData((data?.subdataWithRange(NSRange(location: 5,length:  data!.length - 5)))!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "getUdacityLoginSession", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	
	func getUdacityLogoutSession(var parameters: [String:AnyObject]?, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getUdacityURLFromParameters(parameters, query: nil, replaceQueryString: false)
		request.HTTPMethod = "DELETE"
		
		var xsrfCookie: NSHTTPCookie? = nil
		let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		for cookie in sharedCookieStorage.cookies! {
			if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
		}
		if let xsrfCookie = xsrfCookie {
			request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
		}
		
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData((data?.subdataWithRange(NSRange(location: 5,length:  data!.length - 5)))!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "getUdacityLoginSession", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
			
		return task
		
	}
	
	func getUdacityStudentData(var parameters: [String:AnyObject]?, withUsername username:String, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.APIMethodUsers
		components.query = "/\(username)"
		
		let urlString = components.URL?.absoluteString.stringByReplacingOccurrencesOfString("?", withString: "")
		let request = NSMutableURLRequest(URL: NSURL(string: urlString!)!)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				//subset data for udacity api
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData((data?.subdataWithRange(NSRange(location: 5,length:  data!.length - 5)))!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "getUdacityLoginSession", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	func getFacebookLoginRequest(var parameters: [String:AnyObject]?, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getUdacityURLFromParameters(nil, query: nil, replaceQueryString: false)
		
		request.HTTPMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = "{\"facebook_mobile\": {\"access_token\": \"\(parameters!["accessToken"] as! String)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				//subset data for udacity api
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData((data?.subdataWithRange(NSRange(location: 5,length:  data!.length - 5)))!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "getUdacityLoginSession", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	func getStudentLocations(var parameters: [String:AnyObject]?, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
	
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getURLFromParameters(parameters, query: nil, replaceQueryString: false)
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	func getStudentLocation(var parameters: [String:AnyObject]?, uniqueKey: String, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		
		let queryString = "where={\"uniqueKey\":\"\(uniqueKey)\"}"
		
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getURLFromParameters(nil, query: queryString, replaceQueryString: false)
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	private func emptyString() -> String {
		return ""
	}
	
	func postStudentLocation(var parameters: [String:AnyObject]?, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		
		if parameters == nil {
			parameters = [String:AnyObject]()
		}

		let request = getURLFromParameters(nil, query: nil, replaceQueryString: false)
		request.HTTPMethod = "POST"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		
		let httpBody = "{\"uniqueKey\": \"\(parameters!["uniqueKey"] ?? emptyString())\", \"firstName\": \"\(parameters!["firstName"] ?? emptyString())\", \"lastName\": \"\(parameters!["lastName"] ?? emptyString())\",\"mapString\": \"\(parameters!["mapString"] ?? emptyString())\", \"mediaURL\": \"\(parameters!["mediaURL"] ?? emptyString())\",\"latitude\": \(parameters!["latitude"]!), \"longitude\": \(parameters!["longitude"]!)}"
		
		request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
		
		let task = session.dataTaskWithRequest(request) {data, response, error in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "postStudentLocationCompletionHandler", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
	
		return task
	
	}

	func updateStudentLocation(var parameters: [String:AnyObject]?, objectId: String, completionHandler: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
		
		if parameters == nil {
			parameters = [String:AnyObject]()
		}
		
		let request = getURLFromParameters(nil, query: "/\(objectId)", replaceQueryString: true)
		request.HTTPMethod = "PUT"
		request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
		request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")

		
		let httpBody = "{\"uniqueKey\": \"\(parameters!["uniqueKey"] ?? emptyString())\", \"firstName\": \"\(parameters!["firstName"] ?? emptyString())\", \"lastName\": \"\(parameters!["lastName"] ?? emptyString())\",\"mapString\": \"\(parameters!["mapString"] ?? emptyString())\", \"mediaURL\": \"\(parameters!["mediaURL"] ?? emptyString())\",\"latitude\": \(parameters!["latitude"]!), \"longitude\": \(parameters!["longitude"]!)}"
		
		request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
		
		let task = session.dataTaskWithRequest(request) {data, response, error in
			if let error = self.checkForErrors(data, response: response, error: error) {
				completionHandler(result: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					completionHandler(result: nil, error: NSError(domain: "updateStudentLocationCompletionHandler", code: -1, userInfo: userInfo))
				}
				
				completionHandler(result: parsedResult, error: nil)
			}
		}
		
		task.resume()
		
		return task
		
		
	}
}