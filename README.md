# SideMenu
[![CI Status](http://img.shields.io/travis/jonkykong/SideMenu.svg?style=flat)](https://travis-ci.org/jonkykong/SideMenu)
[![Version](https://img.shields.io/cocoapods/v/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![License](https://img.shields.io/cocoapods/l/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![Platform](https://img.shields.io/cocoapods/p/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)

SideMenu is a simple and versatile side menu control written in Swift. The are three standard animation styles to choose from along with several other options for further customization if desired.

![](etc/Preview.gif)

## Requirements
* Xcode 7 or higher
* iOS 8 or higher
* ARC

## Installation

SideMenu is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SideMenu"
```

## Usage
SideMenu is highly customizable, but can also be implemented in storyboard without a single line of code. Check out the example project to see it in action.

### Storyboard
1. Create a Navigation Controller. Set the custom class of the Navigation Controller to be `UILeftMenuNavigationController` or `UIRightMenuNavigationController` (whichever you prefer) in the **Identity Inspector**.
2. Create a root View Controller for the Navigation Controller in step 1. Set up any Triggered Segues you want in that View Controller.
3. From any View Controller, add a UIButton or UIBarButton. Set that button's Triggered Segues action to modally present the Navigation Controller from step 1.

*Note: you can only enable gestures with code.*

### Code
In your View Controller's `viewDidLoad` event, do something like this:
``` swift
// Define the menus
let leftMenuNavigationController = UILeftMenuNavigationController()
// UILeftMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here
SideMenuManager.menuLeftNavigationController = leftMenuNavigationController
let rightMenuNavigationController = UIRightMenuNavigationController()
// UIRightMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here
SideMenuManager.menuRightNavigationController = rightMenuNavigationController

// Enable gestures. The left and/or right menus must be set up above for these to work.
// Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
```
Then from a button, do something like this:
``` swift
presentViewController(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
```

### Customization
Just type `SideMenuManager.menu...` and code completion will show you everything you can customize (defaults are shown below for reference):
``` swift
menuPresentMode:MenuPresentMode = .ViewSlideOut
menuAllowPushOfSameClassTwice = true
menuAllowPopIfPossible = false
menuWidth: CGFloat = max(round(min(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * 0.75), 240)
menuAnimationPresentDuration = 0.35
menuAnimationDismissDuration = 0.35
menuAnimationFadeStrength: CGFloat = 0
menuAnimationShrinkStrength: CGFloat = 1
menuAnimationBackgroundColor: UIColor? = nil
menuShadowOpacity: Float = 0.5
menuShadowColor = UIColor.blackColor()
menuShadowRadius: CGFloat = 5
menuLeftSwipeToDismissGesture: UIPanGestureRecognizer?
menuRightSwipeToDismissGesture: UIPanGestureRecognizer?
menuParallaxStrength: Int = 0
menuFadeStatusBar = true
menuBlurEffectStyle: UIBlurEffectStyle? = nil // Note: if you want cells in a UITableViewController menu to look good, make them a subclass of UITableViewVibrantCell!
menuLeftNavigationController: UILeftMenuNavigationController? = nil
menuRightNavigationController: UIRightMenuNavigationController? = nil
menuAddScreenEdgePanGesturesToPresent(toView toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer]
menuAddPanGestureToPresent(toView toView: UIView) -> UIPanGestureRecognizer
```

## License

SideMenu is available under the MIT license. See the LICENSE file for more info.
