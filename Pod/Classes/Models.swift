//
//  Models.swift
//  SideMenu
//
//  Created by Jon Kent on 7/3/19.
//

import Foundation

internal protocol MenuModel: TransitionModel {
    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    var allowPushOfSameClassTwice: Bool { get }
    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    var alwaysAnimate: Bool { get }
    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    var blurEffectStyle: UIBlurEffect.Style? { get }
    /// Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
    var completionCurve: UIView.AnimationCurve { get }
    /// Automatically dismisses the menu when another view is presented from it.
    var dismissOnPresent: Bool { get }
    /// Automatically dismisses the menu when another view controller is pushed from it.
    var dismissOnPush: Bool { get }
    /// Automatically dismisses the menu when the screen is rotated.
    var dismissOnRotation: Bool { get }
    /// Automatically dismisses the menu when app goes to the background.
    var dismissWhenBackgrounded: Bool { get }
    /// Enable or disable a swipe gesture that dismisses the menu. Will not be triggered when `presentingViewControllerUserInteractionEnabled` is set to true. Default is true.
    var enableSwipeToDismissGesture: Bool { get }
    /// Enable or disable a tap gesture that dismisses the menu. Will not be triggered when `presentingViewControllerUserInteractionEnabled` is set to true. Default is true.
    var enableTapToDismissGesture: Bool { get }
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
    var pushStyle: SideMenuPushStyle { get }
}

internal protocol TransitionModel: PresentationModel {
    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    var animationOptions: UIView.AnimationOptions { get }
    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    var completeGestureDuration: Double { get }
    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    var dismissDuration: Double { get }
    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    var initialSpringVelocity: CGFloat { get }
    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    var presentDuration: Double { get }
    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    var usingSpringWithDamping: CGFloat { get }
}

internal protocol PresentationModel {
    /// Draws `presentStyle.backgroundColor` behind the status bar. Default is 1.
    var statusBarEndAlpha: CGFloat { get }
    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. `presentingViewControllerUseSnapshot` must also set to false. Default is false.
    var presentingViewControllerUserInteractionEnabled: Bool { get }
    /// Use a snapshot for the presenting vierw controller while the menu is displayed. Useful when layout changes occur during transitions. Not recommended for apps that support rotation. Default is false.
    var presentingViewControllerUseSnapshot: Bool { get }
    /// The presentation style of the menu.
    var presentationStyle: SideMenuPresentationStyle { get }
    /// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is zero.
    var menuWidth: CGFloat { get }
}
