//
//  UIHelper.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

class UIHelper {
	static func handleNSURLSessionLoginResponse(data: NSData?, response:NSURLResponse?, error:NSError? ) -> (AnyObject?, NSError?) {
		
		func displayError(error:String) -> NSError {
			print(error)
			let error = NSError(domain: error, code: -1, userInfo: nil)
			
			return error
		}
		
		//was there an error
		guard (error == nil) else {
			return (nil, displayError("There was an error while attempting to login"))
		}
		
		//did we get a successful response from the API?
		guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
			return (nil, displayError("Login request was unsuccessful"))
		}
		
		//guard was there any data returned
		guard var data = data else {
			return (nil, displayError("User was not found"))
		}
		
		//subset data for udacity api
		data = data.subdataWithRange(NSMakeRange(5, data.length - 5))
		
		let parsedResult: AnyObject!
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			return (parsedResult, nil)
		} catch {
			return (nil, displayError("Could not parse the data as JSON: '\(data)'"))
		}
	}
	
	static func handleNSURLStudentLocationsResponse(data: NSData?, response:NSURLResponse?, error:NSError? ) -> (AnyObject?, NSError?) {
		
		func displayError(error:String) -> NSError {
			print(error)
			let error = NSError(domain: error, code: -1, userInfo: nil)
			
			return error
		}
		
		//was there an error
		guard (error == nil) else {
			print(error)
			return (nil, displayError("There was an error while retrieving student locations"))
		}
		
		//did we get a successful response from the API?
		guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
			return (nil, displayError("Student locations request was unsuccessful"))
		}
		
		//guard was there any data returned
		guard let data = data else {
			return (nil, displayError("Student locations could not be found"))
		}
		
		let parsedResult: AnyObject!
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			return (parsedResult, nil)
		} catch {
			return (nil, displayError("Could not parse the data as JSON: '\(data)'"))
		}
	}
}
