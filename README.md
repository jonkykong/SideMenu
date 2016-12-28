# ▤ SideMenu
[![Version](https://img.shields.io/cocoapods/v/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![Platform](https://img.shields.io/cocoapods/p/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)

## Shameless Plugs
### If you like SideMenu, give it a ★ at the top right of its [GitHub](https://github.com/jonkykong/SideMenu) page.

My name is Jon Kent and I'm a freelance iOS designer, developer, and mobile strategist. I love coffee and play the drums. [**Hire me**](mailto:contact@jonkent.me?subject=Let's build something amazing.) to help you make cool stuff. I also have a [website](http://jonkent.me).

## Overview

SideMenu is a simple and versatile side menu control written in Swift.
* **It can be implemented in storyboard without a single line of [code](#code-less-storyboard-implementation).**
* Four standard animation styles to choose from (even parallax if you want to get weird).
* Highly customizable without needing to write tons of custom code.
* Supports continuous swiping between side menus on boths sides in a single gesture.
* Global menu configuration. Set-up once and be done for all screens.
* Menus can be presented and dismissed the same as any other View Controller since this control uses custom transitions.

Check out the example project to see it in action!

![](etc/SlideOut.gif)
![](etc/SlideIn.gif)
![](etc/Dissolve.gif)
![](etc/InOut.gif)

## Requirements
* iOS 8 or higher

## Installation
### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate SideMenu into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'SideMenu'

# For Swift 2.3, use:
# pod 'SideMenu', '~> 1.2.1'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate SideMenu into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "jonkykong/SideMenu" "master"
```

## Usage
### Code-less Storyboard Implementation
1. Create a Navigation Controller for a side menu. Set the custom class of the Navigation Controller to be `UISideMenuNavigationController` in the **Identity Inspector**. Create a Root View Controller for the Navigation Controller (shown as a UITableViewController below). Set up any Triggered Segues you want in that View Controller.
![](etc/Screenshot1.png)

2. Set the `Left Side` property of the `UISideMenuNavigationController` to On if you want it to appear from the left side of the screen, or Off/Default if you want it to appear from the right side.
![](etc/Screenshot2.png)

3. Add a UIButton or UIBarButton to a View Controller that you want to display the menu from. Set that button's Triggered Segues action to modally present the Navigation Controller from step 1.
![](etc/Screenshot3.png)

That's it. *Note: you can only enable gestures in code.*
### Code Implementation
First:
```swift
import SideMenu
```

In your View Controller's `viewDidLoad` event, do something like this:
``` swift
// Define the menus
let menuLeftNavigationController = UISideMenuNavigationController()
menuLeftNavigationController.leftSide = true
// UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
SideMenuManager.menuLeftNavigationController = menuLeftNavigationController

let menuRightNavigationController = UISideMenuNavigationController()
// UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
SideMenuManager.menuRightNavigationController = menuRightNavigationController

// Enable gestures. The left and/or right menus must be set up above for these to work.
// Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
```
Then from a button, do something like this:
``` swift
present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)

// For Swift 2.3, use:
// presentViewController(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
```
That's it.
### Customization
Just type `SideMenuManager.menu...` and code completion will show you everything you can customize (defaults are shown below for reference):
``` swift
/**
The presentation mode of the menu.

There are four modes in MenuPresentMode:
- menuSlideIn: Menu slides in over of the existing view.
- viewSlideOut: The existing view slides out to reveal the menu.
- viewSlideInOut: The existing view slides out while the menu slides in.
- menuDissolveIn: The menu dissolves in over the existing view controller.
*/
open static var menuPresentMode: MenuPresentMode = .viewSlideOut

/// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
open static var menuAllowPushOfSameClassTwice = true

/// Pops to any view controller already in the navigation stack instead of the view controller being pushed if they share the same class. Defaults to false.
open static var menuAllowPopIfPossible = false

/// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width.
open static var menuWidth: CGFloat = max(round(min((appScreenRect.width), (appScreenRect.height)) * 0.75), 240)

/// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
open static var menuAnimationPresentDuration = 0.35

/// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
open static var menuAnimationDismissDuration = 0.35

/// Amount to fade the existing view controller when the menu is presented. Default is 0 for no fade. Set to 1 to fade completely.
open static var menuAnimationFadeStrength: CGFloat = 0

/// The amount to scale the existing view controller or the menu view controller depending on the `menuPresentMode`. Default is 1 for no scaling. Less than 1 will shrink, greater than 1 will grow.
open static var menuAnimationTransformScaleFactor: CGFloat = 1

/// The background color behind menu animations. Depending on the animation settings this may not be visible. If `menuFadeStatusBar` is true, this color is used to fade it. Default is black.
open static var menuAnimationBackgroundColor: UIColor?

/// The shadow opacity around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 0.5 for 50% opacity.
open static var menuShadowOpacity: Float = 0.5

/// The shadow color around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is black.
open static var menuShadowColor = UIColor.black

/// The radius of the shadow around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 5.
open static var menuShadowRadius: CGFloat = 5

/// The left menu swipe to dismiss gesture.
open static weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer?

/// The right menu swipe to dismiss gesture.
open static weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer?

/// Enable or disable gestures that would swipe to present or dismiss the menu. Default is true.
open static var menuEnableSwipeGestures: Bool = true

/// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. Default is false.
open static var menuPresentingViewControllerUserInteractionEnabled: Bool = false

/// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
open static var menuParallaxStrength: Int = 0

/// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
open static var menuFadeStatusBar = true

/// When true, pushViewController called within the menu it will push the new view controller inside of the menu. Otherwise, it is pushed on the menu's presentingViewController. Default is false.
open static var menuAllowSubmenus: Bool = false

/// When true, pushViewController will replace the last view controller in the navigation controller's viewController stack instead of appending to it. This makes menus similar to tab bar controller behavior.
open static var menuReplaceOnPush: Bool = false

/**
 The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

 - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
 */
open static var menuBlurEffectStyle: UIBlurEffectStyle?

/// The left menu.
open static var menuLeftNavigationController: UISideMenuNavigationController?

/// The right menu.
open static var menuRightNavigationController: UISideMenuNavigationController?

/**
 Adds screen edge gestures to a view to present a menu.

 - Parameter toView: The view to add gestures to.
 - Parameter forMenu: The menu (left or right) you want to add a gesture for. If unspecified, gestur=es will be added for both sides.

 - Returns: The array of screen edge gestures added to `toView`.
 */
@discardableResult open class func menuAddScreenEdgePanGesturesToPresent(toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer]

/**
 Adds a pan edge gesture to a view to present menus.

 - Parameter toView: The view to add a pan gesture to.

 - Returns: The pan gesture added to `toView`.
 */
@discardableResult open class func menuAddPanGestureToPresent(toView: UIView) -> UIPanGestureRecognizer
```

## Known Issues
Don't try to change the status bar appearance when presenting a menu. When used with quick gestures/animations, it causes the presentation animation to not complete properly and locks the UI. This was fixed in iOS 9.3. See [radar 21961293](http://www.openradar.me/21961293) for more information.

## Thank You
A special thank you to everyone that has [contributed](https://github.com/jonkykong/SideMenu/graphs/contributors) to this library to make it better. Your support is appreciated!

## License

SideMenu is available under the MIT license. See the LICENSE file for more info.
