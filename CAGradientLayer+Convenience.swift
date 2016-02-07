//
//  CAGradientLayer+Convenience.swift
//  OnTheMap
//
//  Created by Marquis Dennis on 2/6/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

extension CAGradientLayer {
	func orangeColor() -> CAGradientLayer {
		let topColor = UIColor(red: (237/255.0), green: (162/255.0), blue: (24/255.0), alpha: 1)
		let bottomColor = UIColor(red: (219/255.0), green: (113/255.0), blue: (21/255.0), alpha: 1)
		
		let gradientColors = [topColor.CGColor, bottomColor.CGColor]
		let gradientLocations = [0.0, 1.0]
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = gradientColors
		gradientLayer.locations = gradientLocations
		
		return gradientLayer
	}
}
