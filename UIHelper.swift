//
//  UIHelper.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/9/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

class UIHelper {
	static func activityIndicatorViewLoadingView(center: CGPoint) -> UIView {
		let loadingView: UIView = UIView()
		loadingView.frame = CGRectMake(0, 0, 80, 80)
		loadingView.center = center
		loadingView.backgroundColor = UIColor(red: 107/255.0, green: 105/255.0, blue: 105/255.0, alpha: 0.7)
		loadingView.clipsToBounds = true
		loadingView.layer.cornerRadius = 10
		
		return loadingView
	}
}
