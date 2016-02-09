//
//  GCDBlackbox.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/8/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
	dispatch_async(dispatch_get_main_queue()) {
		updates()
	}
}