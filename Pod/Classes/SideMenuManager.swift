//
//  SideMenuManager.swift
//
//  Created by Jon Kent on 12/6/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

/* Example usage:
     // Define the menus
     SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? UISideMenuNavigationController
     SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as? UISideMenuNavigationController
     
     // Enable gestures. The left and/or right menus must be set up above for these to work.
     // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
     SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
     SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
*/

import UIKit

@objcMembers
open class SideMenuManager: NSObject {

    public enum PresentDirection: Int { case
        left = 1,
        right = 0

        var edge: UIRectEdge {
            switch self {
            case .left: return .left
            case .right: return .right
            }
        }

        var name: String {
            switch self {
            case .left: return "menuLeftNavigationController"
            case .right: return "menuRightNavigationController"
            }
        }
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
//    open var menuPushStyle: MenuPushStyle = .defaultBehavior

    /**
     The presentation stayle of the menu.
     
     There are four modes in MenuPresentStyle:
     - menuSlideIn: Menu slides in over of the existing view.
     - viewSlideOut: The existing view slides out to reveal the menu.
     - viewSlideInOut: The existing view slides out while the menu slides in.
     - menuDissolveIn: The menu dissolves in over the existing view controller.
     */
//    open var menuPresentStyle: MenuPresentStyle = .viewSlideOut

    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
//    open var menuAllowPushOfSameClassTwice = true

    /**
     Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width or 240 points, whichever is smaller.
     
     Note that each menu's width can be overridden using the `menuWidth` property on any `UISideMenuNavigationController` instance.
     */
//    open var menuWidth: CGFloat = {
//        let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
//        let minimumSize = min(appScreenRect.width, appScreenRect.height)
//        return min(round(minimumSize * 0.75), 240)
//    }()

    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
//    open var menuAnimationPresentDuration: Double = 0.35

    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
//    open var menuAnimationDismissDuration: Double = 0.35

    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
//    open var menuAnimationCompleteGestureDuration: Double = 0.35

    /// Amount to fade the existing view controller when the menu is presented. Default is 0 for no fade. Set to 1 to fade completely.
//    open var menuAnimationFadeStrength: CGFloat = 0

    /// The amount to scale the existing view controller or the menu view controller depending on the `menuPresentMode`. Default is 1 for no scaling. Less than 1 will shrink, greater than 1 will grow.
//    open var menuAnimationTransformScaleFactor: CGFloat = 1

    /// The background color behind menu animations. Depending on the animation settings this may not be visible. If `menuFadeStatusBar` is true, this color is used to fade it. Default is black.
//    open var menuAnimationBackgroundColor: UIColor?

    /// The shadow opacity around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 0.5 for 50% opacity.
//    open var menuShadowOpacity: Float = 0.5

    /// The shadow color around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is black.
//    open var menuShadowColor = UIColor.black

    /// The radius of the shadow around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 5.
//    open var menuShadowRadius: CGFloat = 5

    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. Default is false.
//    open var menuPresentingViewControllerUserInteractionEnabled: Bool = false

    /// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
//    open var menuParallaxStrength: Int = 0

    /// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
//    open var menuFadeStatusBar = true

    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
//    open var menuAnimationOptions: UIView.AnimationOptions = .curveEaseInOut

	///	Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
//    open var menuAnimationCompletionCurve: UIView.AnimationCurve = .easeIn

    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
//    open var menuAnimationUsingSpringWithDamping: CGFloat = 1

    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
//    open var menuAnimationInitialSpringVelocity: CGFloat = 1

    /**
     Automatically dismisses the menu when another view is pushed from it.
     
     Note: to prevent the menu from dismissing when presenting, set modalPresentationStyle = .overFullScreen
     of the view controller being presented in storyboard or during its initalization.
     */
//    open var menuDismissOnPush = true

    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
//    open var menuAlwaysAnimate = false

    /// Automatically dismisses the menu when app goes to the background.
//    open var menuDismissWhenBackgrounded = true

    /// Default instance of SideMenuManager.
    public static let `default` = SideMenuManager()

//    public static var globalPresentStyle: MenuPresentStyle = .viewSlideOut
//    public static var globalPushStyle: MenuPushStyle = .defaultBehavior



//    public static var menuOptions = UISideMenuNavigationController.Options()

    /// Default instance of SideMenuManager (objective-C).
    open class var defaultManager: SideMenuManager {
        return SideMenuManager.default
    }

    internal lazy var gestureManager: SideMenuGestureManager = {
        let gestureManager = SideMenuGestureManager()
        gestureManager.delegate = self
        return gestureManager
    }()

    private var rotating: Bool = false
    private weak var switchToMenu: Menu?

    override init() {
        super.init()
        let notificationNames: [NSNotification.Name] = [
            UIApplication.didEnterBackgroundNotification,
            UIApplication.willChangeStatusBarOrientationNotification,
            UIApplication.didChangeStatusBarOrientationNotification,
            UIApplication.willChangeStatusBarFrameNotification
        ]
        notificationNames.forEach {
            NotificationCenter.default.addObserver(self, selector:#selector(handleNotification), name: $0, object: nil)
        }
    }

    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.
     
     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
//    open var menuBlurEffectStyle: UIBlurEffect.Style? {
//        didSet {
//            if oldValue != menuBlurEffectStyle {
//                updateBlurIfNecessary()
//            }
//        }
//    }

    /// The left menu.
    open var menuLeftNavigationController: UISideMenuNavigationController? {
        didSet {
            if !setMenu(from: oldValue, to: menuLeftNavigationController, side: .left) {
                menuLeftNavigationController = oldValue
            }
        }
    }
    
    /// The right menu.
    open var menuRightNavigationController: UISideMenuNavigationController? {
        didSet {
            if !setMenu(from: oldValue, to: menuRightNavigationController, side: .right) {
                menuRightNavigationController = oldValue
            }
        }
    }
    
//    /// The left menu swipe to dismiss gesture.
//    open private(set) weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
//        didSet {
//            oldValue?.view?.removeGestureRecognizer(oldValue!)
//        }
//    }
//
//    /// The right menu swipe to dismiss gesture.
//    open private(set) weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
//        didSet {
//            oldValue?.view?.removeGestureRecognizer(oldValue!)
//        }
//    }

    /// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
//    open var menuEnableSwipeGestures: Bool = true {
//        didSet {
//            setupSwipeGestures()
//        }
//    }

    /**
     Adds screen edge gestures to a view to present a menu.
     
     - Parameter toView: The view to add gestures to.
     - Parameter forMenu: The menu (left or right) you want to add a gesture for. If unspecified, gestures will be added for both sides.
 
     - Returns: The array of screen edge gestures added to `toView`.
     */
    @discardableResult open func menuAddScreenEdgePanGesturesToPresent(toView view: UIView, forMenu sides: [PresentDirection] = [.left, .right]) -> [UIScreenEdgePanGestureRecognizer] {
        sides.forEach { side in
            if menu(forSide: side) == nil {
                let methodName = #function // "menuAddScreenEdgePanGesturesToPresent"
                let suggestedMethodName = "menuAddScreenEdgePanGesturesToPresent(toView:forMenu:)"
                Print.warning(.screenGestureAdded, arguments: methodName, side.name, suggestedMethodName)
            }
        }

        let edges: [UIRectEdge] = sides.map { $0.edge }
        return gestureManager.addPresentScreenEdgePanGestures(to: view, for: edges)
    }
    
    /**
     Adds a pan edge gesture to a view to present menus.
     
     - Parameter toView: The view to add a pan gesture to.
     
     - Returns: The pan gesture added to `toView`.
     */
    @discardableResult open func menuAddPanGestureToPresent(toView view: UIView) -> UIPanGestureRecognizer {
        if menuLeftNavigationController ?? menuRightNavigationController == nil {
            Print.warning(.panGestureAdded, arguments: #function, PresentDirection.left.name, PresentDirection.right.name, required: true)
        }
        
        return gestureManager.addPresentPanGesture(to: view)
    }
}

extension SideMenuManager: SideMenuTransitionControllerDelegate {

    internal func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, animationEnded transitionCompleted: Bool) {
        if transitionController.presenting && transitionCompleted {
            gestureManager.addDismissGestures(to: transitionController.tapView)
            return
        }

        if let switchToMenu = switchToMenu {
            self.switchToMenu = nil
            SideMenuManager.visibleViewController?.present(switchToMenu, animated: true, completion: nil)
        }
    }
}

extension SideMenuManager: SideMenuGestureManagerDelegate {

    internal func gestureManager(_ gestureManager: SideMenuGestureManager, changedState state: SideMenuGestureManager.State, presenting: Bool) {
        guard gestureManager.isTracking else {
            if presenting {
                guard let menu = menu(forLeftSide: gestureManager.leftSide) else { return }
                SideMenuManager.visibleViewController?.present(menu, animated: true, completion: nil)
            } else {
                activeMenu?.dismiss(animated: true, completion: nil)
            }
            return
        }

        switch state {
        case .start(let progress):
            if presenting {
                guard let menu = menu(forLeftSide: gestureManager.leftSide) else { return }
                SideMenuManager.visibleViewController?.present(menu, animated: true, completion: nil)
            } else {
                activeMenu?.dismiss(animated: true, completion: nil)
            }
            activeMenu?.transitionController?.interactionController?.update(progress)
        case .update(let progress):
            activeMenu?.transitionController?.interactionController?.update(progress)
        case .switching:
            switchToMenu = menu(forLeftSide: gestureManager.leftSide)
            activeMenu?.transitionController?.interactionController?.cancel()
        case .finish:
            switchToMenu = nil
            activeMenu?.transitionController?.interactionController?.finish()
        case .cancel:
            switchToMenu = nil
            activeMenu?.transitionController?.interactionController?.cancel()
        }
    }

    internal func gestureManagerWidthForMenu(_ gestureManager: SideMenuGestureManager) -> CGFloat? {
        return menu(forLeftSide: gestureManager.leftSide)?.menuWidth
    }
}

internal extension SideMenuManager {

    func setMenu(_ menu: Menu?, forLeftSide leftSide: Bool) {
        switch leftSide {
        case true: menuLeftNavigationController = menu
        case false: menuRightNavigationController = menu
        }
    }
}

private extension SideMenuManager {

    var activeMenu: Menu? {
        if menuLeftNavigationController?.isHidden == false { return menuLeftNavigationController }
        if menuRightNavigationController?.isHidden == false { return menuRightNavigationController }
        return nil
    }

    func menu(forSide: PresentDirection) -> Menu? {
        switch forSide {
        case .left: return menuLeftNavigationController
        case .right: return menuRightNavigationController
        }
    }

    func menu(forLeftSide leftSide: Bool) -> Menu? {
        return menu(forSide: leftSide ? .left : .right)
    }

    func forEachMenu(_ execute: (Menu) -> Void) {
        [menuLeftNavigationController, menuRightNavigationController].forEach { menu in
            guard let menu = menu else { return }
            execute(menu)
        }
    }

    func setMenu(from: Menu?, to: Menu?, side: PresentDirection) -> Bool {
        guard from != to else { return true }
        if let from = from {
            if !from.isHidden {
                Print.warning(.menuInUse, arguments: side.name, required: true)
                return false
            }
            from.transitioningDelegate = nil
        }
        setupMenu(forSide: side)
        return true
    }

    func setupMenu(forSide side: PresentDirection) {
        guard let menu = menu(forSide: side) else { return }

        menu.transitioningDelegate = menu
        menu.modalPresentationStyle = .custom
        menu.leftSide = side == .left

        if menu.transitioningDelegate !== self {
            let sideMenuManager = menu.transitioningDelegate.self as? SideMenuManager
            Print.warning(.menuAlreadyAssigned, arguments: String(describing: menu.self), side.name, String(describing: sideMenuManager))
            menu.transitioningDelegate = menu
        }

        setupSwipeGestures()

        // Ensures minimal lag when revealing the menu for the first time using gestures by loading the view:
        let _ = menu.topViewController?.view

    }

    func setupSwipeGestures() {
        forEachMenu {
            if let swipeToDismissGesture = $0.swipeToDismissGesture, !$0.enableSwipeGestures {
                swipeToDismissGesture.view?.removeGestureRecognizer(swipeToDismissGesture)
            } else if $0.swipeToDismissGesture == nil && $0.enableSwipeGestures {
                $0.swipeToDismissGesture = gestureManager.addDismissPanGesture(to: $0.view)
            }
        }
    }

    @objc func handleNotification(notification: NSNotification) {
        guard let activeMenu = activeMenu, activeMenu.presentedViewController == nil else { return }

        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            if activeMenu.dismissWhenBackgrounded {
                activeMenu.transitionController?.interactionController?.cancel()
                activeMenu.dismiss(animated: false, completion: nil)
            }
            return
        case UIApplication.willChangeStatusBarOrientationNotification:
            rotating = true
        case UIApplication.didChangeStatusBarOrientationNotification:
            rotating = false
        case UIApplication.willChangeStatusBarFrameNotification:
            if !rotating {
                activeMenu.dismiss(animated: true, completion: nil)
            }
        default: break
        }
    }

    class var visibleViewController: UIViewController? {
        return getVisibleViewController(forViewController: UIApplication.shared.keyWindow?.rootViewController)
    }

    class func getVisibleViewController(forViewController: UIViewController?) -> UIViewController? {
        if let navigationController = forViewController as? UINavigationController {
            return getVisibleViewController(forViewController: navigationController.visibleViewController)
        }
        if let tabBarController = forViewController as? UITabBarController {
            return getVisibleViewController(forViewController: tabBarController.selectedViewController)
        }
        if let splitViewController = forViewController as? UISplitViewController {
            return getVisibleViewController(forViewController: splitViewController.viewControllers.last)
        }
        if let presentedViewController = forViewController?.presentedViewController {
            return getVisibleViewController(forViewController: presentedViewController)
        }

        return forViewController
    }
}

//extension SideMenuManager: MenuOptions {
//    var allowPushOfSameClassTwice: Bool {
//        <#code#>
//    }
//
//    var alwaysAnimate: Bool {
//        <#code#>
//    }
//
//    var animationOptions: UIView.AnimationOptions {
//        <#code#>
//    }
//
//    var completeGestureDuration: Double {
//        <#code#>
//    }
//
//    var completionCurve: UIView.AnimationCurve {
//        <#code#>
//    }
//
//    var dismissDuration: Double {
//        <#code#>
//    }
//
//    var dismissOnPresent: Bool {
//        <#code#>
//    }
//
//    var dismissOnPush: Bool {
//        <#code#>
//    }
//
//    var dismissWhenBackgrounded: Bool {
//        <#code#>
//    }
//
//    var initialSpringVelocity: CGFloat {
//        <#code#>
//    }
//
//    var presentDuration: Double {
//        <#code#>
//    }
//
//    var presentStyle: MenuPresentStyle {
//        <#code#>
//    }
//
//    var pushStyle: MenuPushStyle {
//        <#code#>
//    }
//
//    var usingSpringWithDamping: CGFloat {
//        <#code#>
//    }
//
//}

// Deprecations, to be removed at a future date.
extension SideMenuManager {
//    @available(*, deprecated, renamed: "menuPresentStyle")
//    open var menuPresentMode: MenuPresentStyle {
//        get { return menuPresentStyle }
//        set { menuPresentStyle = newValue }
//    }
}
