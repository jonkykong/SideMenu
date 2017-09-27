# ▤ SideMenu
[![Version](https://img.shields.io/cocoapods/v/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)
[![Platform](https://img.shields.io/cocoapods/p/SideMenu.svg?style=flat)](http://cocoapods.org/pods/SideMenu)

### If you like SideMenu, give it a ★ at the top right of this page.
#### Using SideMenu in your app? [Send](mailto:yo@massappeal.co?subject=SideMenu%20in%20action!) me a link to your app in the app store!

> Hi, I'm Jon Kent and I am an iOS designer, developer, and mobile strategist. I love coffee and play the drums.
> * [**Hire me**](mailto:yo@massappeal.co?subject=Let's%20build%20something%20amazing) to help you make cool stuff. *Note: If you're having a problem with SideMenu, please open an [issue](https://github.com/jonkykong/SideMenu/issues/new) and do not email me.*
> * Check out my [website](http://massappeal.co) to see some of my other projects.
> * Building and maintaining this free library takes time. Help keep me awake and buy me a coffee ☕️ via [PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=contact%40jonkent%2eme&lc=US&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted).

## Overview

SideMenu is a simple and versatile side menu control written in Swift.
 * **It can be implemented in storyboard without a single line of [code](#code-less-storyboard-implementation).**
 * Four standard animation styles to choose from (there's even a parallax effect if you want to get weird).
 * Highly customizable without needing to write tons of custom code.
 * Supports continuous swiping between side menus on boths sides in a single gesture.
 * Global menu configuration. Set-up once and be done for all screens.
 * Menus can be presented and dismissed the same as any other view controller since this control uses [custom transitions](https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html).
 * Animations use your view controllers, not snapshots.
 * Properly handles screen rotation and in-call status bar height changes.

Check out the example project to see it in action!
### Preview Samples
| Slide Out | Slide In | Dissolve | Slide In + Out |
| --- | --- | --- | --- |
| ![](etc/SlideOut.gif) | ![](etc/SlideIn.gif) | ![](etc/Dissolve.gif) | ![](etc/InOut.gif) |

## Requirements
 * iOS 8 or higher.

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

# For Swift 3 (no longer maintained), use:
# pod 'SideMenu', '~> 2.3.4'
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
1. Create a Navigation Controller for a side menu. Set the `Custom Class` of the Navigation Controller to be `UISideMenuNavigationController` in the **Identity Inspector**. Set the `Module` to `SideMenu` (ignore this step if you've manually added SideMenu to your project). Create a Root View Controller for the Navigation Controller (shown as a UITableViewController below). Set up any Triggered Segues you want in that view controller.
![](etc/Screenshot1.png)

2. Set the `Left Side` property of the `UISideMenuNavigationController` to On if you want it to appear from the left side of the screen, or Off/Default if you want it to appear from the right side.
![](etc/Screenshot2.png)

3. Add a UIButton or UIBarButton to a view controller that you want to display the menu from. Set that button's Triggered Segues action to modally present the Navigation Controller from step 1.
![](etc/Screenshot3.png)

That's it. *Note: you can only enable gestures in code.*
### Code Implementation
First:
```swift
import SideMenu
```

In your view controller's `viewDidLoad` event, do something like this (**IMPORTANT: If you're seeing a black menu when you use gestures, read this section carefully!**):
``` swift
// Define the menus
let menuLeftNavigationController = UISideMenuNavigationController(rootViewController: YourViewController)
menuLeftNavigationController.leftSide = true
// UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration 
// of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
// let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
SideMenuManager.menuLeftNavigationController = menuLeftNavigationController

let menuRightNavigationController = UISideMenuNavigationController(rootViewController: YourViewController)
// UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration
// of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
// let menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as! UISideMenuNavigationController
SideMenuManager.menuRightNavigationController = menuRightNavigationController

// Enable gestures. The left and/or right menus must be set up above for these to work.
// Note that these continue to work on the Navigation Controller independent of the view controller it displays!
SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
```
Then from a button, do something like this:
``` swift
present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)

// Similarly, to dismiss a menu programmatically, you would do this:
dismiss(animated: true, completion: nil)
```
That's it.
### Customization
Just type `SideMenuManager.menu...` and code completion will show you everything you can customize (defaults are shown below for reference):
``` swift
/**
The push style of the menu.

There are six modes in MenuPushStyle:
- defaultBehavior: The view controller is pushed onto the stack.
- popWhenPossible: If a view controller already in the stack is of the same class as the pushed view controller, the stack is instead popped back to the existing view controller. This behavior can help users from getting lost in a deep navigation stack.
- preserve: If a view controller already in the stack is of the same class as the pushed view controller, the existing view controller is pushed to the end of the stack. This behavior is similar to a UITabBarController.
- preserveAndHideBackButton: Same as .preserve and back buttons are automatically hidden.
- replace: Any existing view controllers are released from the stack and replaced with the pushed view controller. Back buttons are automatically hidden. This behavior is ideal if view controllers require a lot of memory or their state doesn't need to be preserved..
- subMenu: Unlike all other behaviors that push using the menu's presentingViewController, this behavior pushes view controllers within the menu.  Use this behavior if you want to display a sub menu.
*/
open static var menuPushStyle: MenuPushStyle = .defaultBehavior

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

/**
Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width.

Note that each menu's width can be overridden using the `menuWidth` property on any `UISideMenuNavigationController` instance.
*/
open static var menuWidth: CGFloat = max(round(min((appScreenRect.width), (appScreenRect.height)) * 0.75), 240)

/// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
open static var menuAnimationPresentDuration: Double = 0.35

/// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
open static var menuAnimationDismissDuration: Double = 0.35

/// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
open static var menuAnimationCompleteGestureDuration: Double = 0.35

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

/// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
open static var menuEnableSwipeGestures: Bool = true

/// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. Default is false.
open static var menuPresentingViewControllerUserInteractionEnabled: Bool = false

/// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
open static var menuParallaxStrength: Int = 0

/// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
open static var menuFadeStatusBar = true

/// The animation options when a menu is displayed. Ignored when displayed with a gesture.
open static var menuAnimationOptions: UIViewAnimationOptions = .curveEaseInOut

/// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
open static var menuAnimationUsingSpringWithDamping: CGFloat = 1

/// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
open static var menuAnimationInitialSpringVelocity: CGFloat = 1

/** 
Automatically dismisses the menu when another view is pushed from it.

Note: to prevent the menu from dismissing when presenting, set modalPresentationStyle = .overFullScreen
of the view controller being presented in storyboard or during its initalization.
*/
open static var menuDismissOnPush = true

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
