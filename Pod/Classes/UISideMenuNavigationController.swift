//
//  UISideMenuNavigationController.swift
//
//  Created by Jon Kent on 1/14/16.
//  Copyright © 2016 Jon Kent. All rights reserved.
//

import UIKit

@objc public enum MenuPushStyle: Int {
    case defaultBehavior,
    popWhenPossible,
    replace,
    preserve,
    preserveAndHideBackButton,
    subMenu
}

internal protocol MenuOptions {
    var allowPushOfSameClassTwice: Bool { get }
    var alwaysAnimate: Bool { get }
    var animationOptions: UIView.AnimationOptions { get }
    var blurEffectStyle: UIBlurEffect.Style? { get }
    var completeGestureDuration: Double { get }
    var completionCurve: UIView.AnimationCurve { get }
    var dismissDuration: Double { get }
    var dismissOnPresent: Bool { get }
    var dismissOnPush: Bool { get }
    var dismissWhenBackgrounded: Bool { get }
    var enableSwipeGestures: Bool { get }
    var initialSpringVelocity: CGFloat { get }
    var presentingViewControllerUserInteractionEnabled: Bool { get }
    var presentingViewControllerUseSnapshot: Bool { get } // TODO
    var presentDuration: Double { get }
    var presentStyle: MenuPresentStyle { get }
    var pushStyle: MenuPushStyle { get }
    var usingSpringWithDamping: CGFloat { get }
    var menuWidth: CGFloat { get }
}

@objc public protocol UISideMenuNavigationControllerDelegate {
    @objc optional func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool)
}

internal protocol UISideMenuNavigationControllerManagerDelegate: class {
    func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool) -> Bool
    func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool) -> Bool
    func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool) -> Bool
    func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool) -> Bool
    func sideMenuWillTransition(menu: Menu, to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    func sideMenuShouldPushViewController(menu: Menu, viewController: UIViewController, animated: Bool, completion: ((Bool) -> Void)?) -> Bool
}

internal typealias Menu = UISideMenuNavigationController

@objcMembers
open class UISideMenuNavigationController: UINavigationController {

    private enum PropertyName: String { case
        leftSide
    }

    public struct Options: MenuOptions {
        var allowPushOfSameClassTwice: Bool = true
        var alwaysAnimate: Bool = true
        var animationOptions: UIView.AnimationOptions = .curveEaseInOut
        var blurEffectStyle: UIBlurEffect.Style? = nil
        var completeGestureDuration: Double = 0.35
        var completionCurve: UIView.AnimationCurve = .easeIn
        var dismissDuration: Double = 0.35
        var dismissOnPresent: Bool = true
        var dismissOnPush: Bool = true
        var dismissWhenBackgrounded: Bool = true
        var enableSwipeGestures: Bool = true
        var initialSpringVelocity: CGFloat = 1
        var presentingViewControllerUserInteractionEnabled: Bool = false
        var presentingViewControllerUseSnapshot: Bool = false
        var presentDuration: Double = 0.35
        var presentStyle: MenuPresentStyle = .viewSlideOut
        var pushStyle: MenuPushStyle = .defaultBehavior
        var usingSpringWithDamping: CGFloat = 1
        var menuWidth: CGFloat = {
            let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
            let minimumSize = min(appScreenRect.width, appScreenRect.height)
            return min(round(minimumSize * 0.75), 240)
        }()
    }

    open var options = Options() {
        didSet {
            if options.blurEffectStyle != oldValue.blurEffectStyle && isViewLoaded {
                setupBlur()
            }
        }
    }

    /// Delegate for receiving appear and disappear related events. If `nil` the visible view controller that displays a `UISideMenuNavigationController` automatically receives these events.
    open weak var sideMenuDelegate: UISideMenuNavigationControllerDelegate?

    /// The swipe to dismiss gesture.
    open internal(set) weak var swipeToDismissGesture: UIPanGestureRecognizer? = nil

    internal weak var sideMenuManagerDelegate: UISideMenuNavigationControllerManagerDelegate?

    private var originalBackgroundColor: UIColor?
    private weak var foundDelegate: UISideMenuNavigationControllerDelegate?
    private weak var interactionController: SideMenuInteractionController?
    private var _options: Options?
    private lazy var _leftSide = Protected(false, if: condition, else: { _ in Menu.elseCondition(.leftSide) } )
    private var _sideMenuManager: SideMenuManager?
    private var transitionController: SideMenuTransitionController?
    private var rotating: Bool = false

    open var sideMenuManager: SideMenuManager {
        get { return _sideMenuManager ?? SideMenuManager.default }
        set { _sideMenuManager = newValue }
    }
    
    #if !STFU_SIDEMENU
    // This override prevents newbie developers from creating black/blank menus and opening newbie issues.
    // If you would like to remove this override, define STFU_SIDEMENU in the Active Compilation Conditions of your .plist file.
    // Sorry for the inconvenience experienced developers :(
    @available(*, unavailable, renamed: "init(rootViewController:)")
    public init() {
        fatalError("init is not available")
    }
    
//    public override init(rootViewController: UIViewController) {
//        super.init(rootViewController: rootViewController)
//    }
//
//    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//    }
    #endif

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForNotifications()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        sideMenuManager.setMenu(self, forLeftSide: leftSide)
        setupBlur()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBlur()

        guard sideMenuManagerDelegate?.sideMenuWillAppear(menu: self, animated: true) == true else { return }
        foundDelegate = nil
        activeDelegate?.sideMenuWillAppear?(menu: self, animated: animated)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard sideMenuManagerDelegate?.sideMenuDidAppear(menu: self, animated: animated) == true else { return }
        activeDelegate?.sideMenuDidAppear?(menu: self, animated: animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard sideMenuManagerDelegate?.sideMenuWillDisappear(menu: self, animated: animated) == true else { return }
        activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard sideMenuManagerDelegate?.sideMenuDidDisappear(menu: self, animated: animated) == true else { return }
        activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        sideMenuManagerDelegate?.sideMenuWillTransition(menu: self, to: size, with: coordinator)
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        let push = sideMenuManagerDelegate?.sideMenuShouldPushViewController(menu: self, viewController: viewController, animated: animated) { [weak self] _ in
            self?.foundDelegate = nil
        } ?? true
        
        if push {
            super.pushViewController(viewController, animated: animated)
        }
    }

    /// Indicates if the menu is anywhere in the view hierarchy, even if covered by another view controller.
    open var isHidden: Bool {
        return presentingViewController == nil
    }

    /// Whether the menu appears on the right or left side of the screen. Right is the default. This property cannot be changed after the menu has loaded.
    @IBInspectable open var leftSide: Bool {
        get { return _leftSide.value }
        set { _leftSide.value = newValue }
    }
}

// IMPORTANT: These methods must be declared open or they will not be called.
extension UISideMenuNavigationController: UIViewControllerTransitioningDelegate {

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let menu = presented as? Menu else { return nil }
        transitionController = SideMenuTransitionController(menu: menu)
        transitionController?.interactive = sideMenuManager.isTracking
        transitionController?.delegate = sideMenuManager
        return transitionController
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController?.interactive = sideMenuManager.isTracking
        return transitionController
    }

    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    open func interactionController(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard sideMenuManager.isTracking else { return nil }
        let interactionController = SideMenuInteractionController(completionCurve: options.completionCurve)
        self.interactionController = interactionController
        let transitionController = animator as? SideMenuTransitionController
        transitionController?.interactive = true
        return interactionController
    }
}

extension UISideMenuNavigationController: SideMenuInteractable {

    func handle(state: SideMenuInteractionController.State) {
        interactionController?.handle(state: state)
    }
}

// Interface
extension UISideMenuNavigationController: MenuOptions {

    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    var allowPushOfSameClassTwice: Bool {
        get { return options.allowPushOfSameClassTwice }
        set { options.allowPushOfSameClassTwice = newValue }
    }

    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    @IBInspectable var alwaysAnimate: Bool {
        get { return options.alwaysAnimate }
        set { options.alwaysAnimate = newValue }
    }

    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    open var animationOptions: UIView.AnimationOptions {
        get { return options.animationOptions }
        set { options.animationOptions = newValue }
    }

    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    open var blurEffectStyle: UIBlurEffect.Style? {
        get { return options.blurEffectStyle }
        set { options.blurEffectStyle = newValue }
    }

    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    @IBInspectable open var completeGestureDuration: Double {
        get { return options.completeGestureDuration }
        set { options.completeGestureDuration = newValue }
    }

    /// Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
    @IBInspectable open var completionCurve: UIView.AnimationCurve {
        get { return options.completionCurve }
        set { options.completionCurve = newValue }
    }

    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    @IBInspectable open var dismissDuration: Double {
        get { return options.dismissDuration }
        set { options.dismissDuration = newValue }
    }

    /// Automatically dismisses the menu when app goes to the background.
    @IBInspectable open var dismissWhenBackgrounded: Bool {
        get { return options.dismissWhenBackgrounded }
        set { options.dismissWhenBackgrounded = newValue }
    }

    /// Automatically dismisses the menu when another view is presented from it.
    @IBInspectable open var dismissOnPresent: Bool {
        get { return options.dismissOnPush }
        set { options.dismissOnPush = newValue }
    }

    /// Automatically dismisses the menu when another view controller is pushed from it.
    @IBInspectable open var dismissOnPush: Bool {
        get { return options.dismissOnPush }
        set { options.dismissOnPush = newValue }
    }

    /// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
    @IBInspectable open var enableSwipeGestures: Bool {
        get { return options.enableSwipeGestures }
        set { options.enableSwipeGestures = newValue }
    }

    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    @IBInspectable open var initialSpringVelocity: CGFloat {
        get { return options.initialSpringVelocity }
        set { options.initialSpringVelocity = newValue }
    }

    /// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is zero.
    @IBInspectable open var menuWidth: CGFloat {
        get { return options.menuWidth }
        set { options.menuWidth = newValue }
    }

    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. `presentingViewControllerUseSnapshot` must also set to false. Default is false.
    @IBInspectable open var presentingViewControllerUserInteractionEnabled: Bool {
        get { return options.presentingViewControllerUserInteractionEnabled }
        set { options.presentingViewControllerUserInteractionEnabled = newValue }
    }

    /// Use a snapshot for the presenting vierw controller while the menu is displayed. Useful when layout changes occur during transitions. Not recommended for apps that support rotation. Default is false.
    @IBInspectable open var presentingViewControllerUseSnapshot: Bool {
        get { return options.presentingViewControllerUseSnapshot }
        set { options.presentingViewControllerUseSnapshot = newValue }
    }

    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    @IBInspectable var presentDuration: Double {
        get { return options.presentDuration }
        set { options.presentDuration = newValue }
    }

    /**
     The presentation stayle of the menu.

     There are four modes in MenuPresentStyle:
     - menuSlideIn: Menu slides in over of the existing view.
     - viewSlideOut: The existing view slides out to reveal the menu.
     - viewSlideInOut: The existing view slides out while the menu slides in.
     - menuDissolveIn: The menu dissolves in over the existing view controller.
     */
    @IBInspectable open var presentStyle: MenuPresentStyle {
        get { return options.presentStyle }
        set { options.presentStyle = newValue }
    }

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
    @IBInspectable open var pushStyle: MenuPushStyle {
        get { return options.pushStyle }
        set { options.pushStyle = newValue }
    }

    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    @IBInspectable var usingSpringWithDamping: CGFloat {
        get { return options.usingSpringWithDamping }
        set { options.usingSpringWithDamping = newValue }
    }
}

internal extension UISideMenuNavigationController {

    weak var activeDelegate: UISideMenuNavigationControllerDelegate? {
        guard !view.isHidden else { return nil }
        return sideMenuDelegate ?? foundDelegate ?? findDelegate(forViewController: presentingViewController)
    }

    @objc func handleNotification(notification: NSNotification) {
        guard presentedViewController == nil else { return }

        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            if dismissWhenBackgrounded {
                interactionController?.cancel()
                dismiss(animated: false, completion: nil)
            }
            return
        case UIApplication.willChangeStatusBarOrientationNotification:
            rotating = true
        case UIApplication.didChangeStatusBarOrientationNotification:
            rotating = false
        case UIApplication.willChangeStatusBarFrameNotification:
            if !rotating {
                dismiss(animated: true, completion: nil)
            }
        default: break
        }
    }
}

private extension UISideMenuNavigationController {

    func registerForNotifications() {
        [UIApplication.didEnterBackgroundNotification,
         UIApplication.willChangeStatusBarOrientationNotification,
         UIApplication.didChangeStatusBarOrientationNotification,
         UIApplication.willChangeStatusBarFrameNotification
        ].forEach {
            NotificationCenter.default.addObserver(self, selector:#selector(handleNotification), name: $0, object: nil)
        }
    }

    func condition() -> Bool {
        return isHidden
    }

    private class func elseCondition(_ propertyName: PropertyName) {
        Print.warning(.property, arguments: propertyName.rawValue, required: true)
    }

    func findDelegate(forViewController: UIViewController?) -> UISideMenuNavigationControllerDelegate? {
        if let navigationController = forViewController as? UINavigationController {
            return findDelegate(forViewController: navigationController.topViewController)
        }
        if let tabBarController = forViewController as? UITabBarController {
            return findDelegate(forViewController: tabBarController.selectedViewController)
        }
        if let splitViewController = forViewController as? UISplitViewController {
            return findDelegate(forViewController: splitViewController.viewControllers.last)
        }

        foundDelegate = forViewController as? UISideMenuNavigationControllerDelegate
        return foundDelegate
    }

    func setupBlur() {
        removeBlur()

        guard let blurEffectStyle = blurEffectStyle,
            let view = topViewController?.view,
            !UIAccessibility.isReduceTransparencyEnabled else {
                return
        }

        originalBackgroundColor = originalBackgroundColor ?? view.backgroundColor

        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clear
        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, at: 0)
        }
    }

    func removeBlur() {
        guard let originalBackgroundColor = originalBackgroundColor,
            let view = topViewController?.view else {
                return
        }

        self.originalBackgroundColor = nil
        view.backgroundColor = originalBackgroundColor

        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = nil
            tableViewController.tableView.separatorEffect = nil
            tableViewController.tableView.reloadData()
        } else if let blurView = view.subviews.first as? UIVisualEffectView {
            blurView.removeFromSuperview()
        }
    }
}
