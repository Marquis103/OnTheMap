# OnTheMap
iOS app the allows Udacity class members to post interests from a location on a map as a link annotated pin and view interests of all users

### Setup Using CocoaPods
* pod init

* Open Podfile and add the following text:
  platform :ios, '9.1'
  use_frameworks!

  target 'OnTheMap' do

  pod 'FBSDKCoreKit', '~> 4.8'
  pod 'FBSDKLoginKit', '~> 4.8'

  end
  
* pod install
