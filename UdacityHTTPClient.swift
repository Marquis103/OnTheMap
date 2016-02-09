//
//  UdacityHTTPClient.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/8/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

class UdacityHTTPClient {
	
	//implement singleton design pattern
	static let sharedInstance: UdacityHTTPClient = UdacityHTTPClient()
	var appDelegate: AppDelegate!
	
	private var url:NSURL?
	
	init() {
		appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	}
	
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
	
	func userAlert(title:String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(alertAction)
		//presentViewController(alert, animated: true, completion: nil)
	}
	
	func handleNSURLSessionResponse(data: NSData?, response:NSURLResponse?, error:NSError? ) -> AnyObject? {
		func displayError(error:String) {
			print(error)
			self.appDelegate.loginSuccessful = false
		}
		
		//was there an error
		guard (error == nil) else {
			displayError("There was an error while attempting to login")
			return nil
		}
		
		//did we get a successful response from the API?
		guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
			displayError("Login request was unsuccessful")
			return nil
		}
		
		//guard was there any data returned
		guard var data = data else {
			displayError("User was not found")
			return nil
		}
		
		//subset data for udacity api
		data = data.subdataWithRange(NSMakeRange(5, data.length - 5))
		
		let parsedResult: AnyObject!
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			return parsedResult
		} catch {
			displayError("Could not parse the data as JSON: '\(data)'")
			return nil
		}
	}
	
	func getUdacitySession(username: String, password: String) {
		let components = NSURLComponents()
		components.scheme = Constants.UdacityClient.ApiScheme
		components.host = Constants.UdacityClient.ApiHost
		components.path = Constants.UdacityClient.ApiPath + Constants.UdacityClient.ApiMethod

		let request = NSMutableURLRequest(URL: components.URL!)
		request.HTTPMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
		
		let task = appDelegate.sharedSession.dataTaskWithRequest(request) { data, response, error in
			
			func displayError(error:String) {
				print(error)
				self.appDelegate.loginSuccessful = false
			}
			
			//if there is a parsed result and the session id exists set it
			if let parsedResult = self.handleNSURLSessionResponse(data, response: response, error: error) {
				//is the session token in the parsed results
				guard let sessionToken = parsedResult[Constants.UdacityResponseKeys.session]!![Constants.UdacityResponseKeys.session_id] as? String else {
					displayError("Could not locate session id")
					return
				}
				
				self.appDelegate.sessionId = sessionToken
			}
		}
		
		task.resume()
	}
}