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

@objcMembers
open class SideMenuManager: NSObject {
    
    @objc public enum MenuPushStyle: Int {
        case defaultBehavior,
        popWhenPossible,
        replace,
        preserve,
        preserveAndHideBackButton,
        subMenu
    }
    
    @objc public enum MenuPresentMode: Int {
        case menuSlideIn,
        viewSlideOut,
        viewSlideInOut,
        menuDissolveIn
    }
    
    // Bounds which has been allocated for the app on the whole device screen
    internal static var appScreenRect: CGRect {
        let appWindowRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
        return appWindowRect
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
    open var menuPushStyle: MenuPushStyle = .defaultBehavior

    /**
     The presentation mode of the menu.
     
     There are four modes in MenuPresentMode:
     - menuSlideIn: Menu slides in over of the existing view.
     - viewSlideOut: The existing view slides out to reveal the menu.
     - viewSlideInOut: The existing view slides out while the menu slides in.
     - menuDissolveIn: The menu dissolves in over the existing view controller.
     */
    open var menuPresentMode: MenuPresentMode = .viewSlideOut
    
    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    open var menuAllowPushOfSameClassTwice = true

    /**
     Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width or 240 points, whichever is smaller.
     
     Note that each menu's width can be overridden using the `menuWidth` property on any `UISideMenuNavigationController` instance.
     */
    open var menuWidth: CGFloat = min(round(min((appScreenRect.width), (appScreenRect.height)) * 0.75), 240)
    
    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    open var menuAnimationPresentDuration: Double = 0.35
    
    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    open var menuAnimationDismissDuration: Double = 0.35
    
    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    open var menuAnimationCompleteGestureDuration: Double = 0.35
    
    /// Amount to fade the existing view controller when the menu is presented. Default is 0 for no fade. Set to 1 to fade completely.
    open var menuAnimationFadeStrength: CGFloat = 0
    
    /// The amount to scale the existing view controller or the menu view controller depending on the `menuPresentMode`. Default is 1 for no scaling. Less than 1 will shrink, greater than 1 will grow.
    open var menuAnimationTransformScaleFactor: CGFloat = 1
    
    /// The background color behind menu animations. Depending on the animation settings this may not be visible. If `menuFadeStatusBar` is true, this color is used to fade it. Default is black.
    open var menuAnimationBackgroundColor: UIColor?
    
    /// The shadow opacity around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 0.5 for 50% opacity.
    open var menuShadowOpacity: Float = 0.5
    
    /// The shadow color around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is black.
    open var menuShadowColor = UIColor.black
    
    /// The radius of the shadow around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 5.
    open var menuShadowRadius: CGFloat = 5
    
    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. Default is false.
    open var menuPresentingViewControllerUserInteractionEnabled: Bool = false
    
    /// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
    open var menuParallaxStrength: Int = 0
    
    /// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
    open var menuFadeStatusBar = true
    
    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    open var menuAnimationOptions: UIView.AnimationOptions = .curveEaseInOut

	///	Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
	open var menuAnimationCompletionCurve: UIView.AnimationCurve = .easeIn
    
    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    open var menuAnimationUsingSpringWithDamping: CGFloat = 1
    
    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    open var menuAnimationInitialSpringVelocity: CGFloat = 1
    
    /**
     Automatically dismisses the menu when another view is pushed from it.
     
     Note: to prevent the menu from dismissing when presenting, set modalPresentationStyle = .overFullScreen
     of the view controller being presented in storyboard or during its initalization.
     */
    open var menuDismissOnPush = true
    
    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    open var menuAlwaysAnimate = false
    
    /// Default instance of SideMenuManager.
    public static let `default` = SideMenuManager()
    
    /// Default instance of SideMenuManager (objective-C).
    open class var defaultManager: SideMenuManager {
        return SideMenuManager.default
    }
    
    internal var transition: SideMenuTransition!
    
    public override init() {
        super.init()
        transition = SideMenuTransition(sideMenuManager: self)
    }
    
    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.
     
     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    open var menuBlurEffectStyle: UIBlurEffect.Style? {
        didSet {
            if oldValue != menuBlurEffectStyle {
                updateMenuBlurIfNecessary()
            }
        }
    }
    
    /// The left menu.
    open var menuLeftNavigationController: UISideMenuNavigationController? {
        willSet {
            guard menuLeftNavigationController != newValue, menuLeftNavigationController?.presentingViewController == nil else {
                return
            }
            menuLeftNavigationController?.locked = false
            removeMenuBlurForMenu(menuLeftNavigationController)
        }
        didSet {
            guard menuLeftNavigationController != oldValue else {
                return
            }
            guard oldValue?.presentingViewController == nil else {
                print("SideMenu Warning: menuLeftNavigationController cannot be modified while it's presented.")
                menuLeftNavigationController = oldValue
                return
            }
            
            setupNavigationController(menuLeftNavigationController, leftSide: true)
        }
    }
    
    /// The right menu.
    open var menuRightNavigationController: UISideMenuNavigationController? {
        willSet {
            guard menuRightNavigationController != newValue, menuRightNavigationController?.presentingViewController == nil else {
                return
            }
            removeMenuBlurForMenu(menuRightNavigationController)
        }
        didSet {
            guard menuRightNavigationController != oldValue else {
                return
            }
            guard oldValue?.presentingViewController == nil else {
                print("SideMenu Warning: menuRightNavigationController cannot be modified while it's presented.")
                menuRightNavigationController = oldValue
                return
            }
            setupNavigationController(menuRightNavigationController, leftSide: false)
        }
    }
    
    /// The left menu swipe to dismiss gesture.
    open weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
        didSet {
            oldValue?.view?.removeGestureRecognizer(oldValue!)
            setupGesture(gesture: menuLeftSwipeToDismissGesture)
        }
    }
    
    /// The right menu swipe to dismiss gesture.
    open weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
        didSet {
            oldValue?.view?.removeGestureRecognizer(oldValue!)
            setupGesture(gesture: menuRightSwipeToDismissGesture)
        }
    }
    
    fileprivate func setupGesture(gesture: UIPanGestureRecognizer?) {
        guard let gesture = gesture else {
            return
        }
        
        gesture.addTarget(transition, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
    }
    
    fileprivate func setupNavigationController(_ forMenu: UISideMenuNavigationController?, leftSide: Bool) {
        guard let forMenu = forMenu else {
            return
        }
        
        forMenu.transitioningDelegate = transition
        forMenu.modalPresentationStyle = .overFullScreen
        forMenu.leftSide = leftSide
        
        if forMenu.sideMenuManager != self {
            #if !STFU_SIDEMENU
            if forMenu.sideMenuManager?.menuLeftNavigationController == forMenu {
                print("SideMenu Warning: \(String(describing: forMenu.self)) was already assigned to the menuLeftNavigationController of \(String(describing: forMenu.sideMenuManager!.self)). When using multiple SideMenuManagers you may want to use new instances of UISideMenuNavigationController instead of existing instances to avoid crashes if the menu is presented more than once.")
            } else if forMenu.sideMenuManager?.menuRightNavigationController == forMenu {
                print("SideMenu Warning: \(String(describing: forMenu.self)) was already assigned to the menuRightNavigationController of \(String(describing: forMenu.sideMenuManager!.self)). When using multiple SideMenuManagers you may want to use new instances of UISideMenuNavigationController instead of existing instances to avoid crashes if the menu is presented more than once.")
            }
            #endif
            forMenu.sideMenuManager = self
        }
        
        forMenu.locked = true
        
        if menuEnableSwipeGestures {
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.cancelsTouchesInView = false
            forMenu.view.addGestureRecognizer(exitPanGesture)
            if leftSide {
                menuLeftSwipeToDismissGesture = exitPanGesture
            } else {
                menuRightSwipeToDismissGesture = exitPanGesture
            }
        }
        
        // Ensures minimal lag when revealing the menu for the first time using gestures by loading the view:
        let _ = forMenu.topViewController?.view
        
        updateMenuBlurIfNecessary()
    }
    
    /// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
    open var menuEnableSwipeGestures: Bool = true {
        didSet {
            menuLeftSwipeToDismissGesture?.view?.removeGestureRecognizer(menuLeftSwipeToDismissGesture!)
            menuRightSwipeToDismissGesture?.view?.removeGestureRecognizer(menuRightSwipeToDismissGesture!)
            setupNavigationController(menuLeftNavigationController, leftSide: true)
            setupNavigationController(menuRightNavigationController, leftSide: false)
        }
    }
    
    fileprivate func updateMenuBlurIfNecessary() {
        if let menuLeftNavigationController = self.menuLeftNavigationController {
            setupMenuBlurForMenu(menuLeftNavigationController)
        }
        if let menuRightNavigationController = self.menuRightNavigationController {
            setupMenuBlurForMenu(menuRightNavigationController)
        }
    }
    
    fileprivate func setupMenuBlurForMenu(_ forMenu: UISideMenuNavigationController?) {
        removeMenuBlurForMenu(forMenu)
        
        guard let forMenu = forMenu,
            let menuBlurEffectStyle = menuBlurEffectStyle,
            let view = forMenu.topViewController?.view,
            !UIAccessibility.isReduceTransparencyEnabled else {
                return
        }
        
        if forMenu.originalMenuBackgroundColor == nil {
            forMenu.originalMenuBackgroundColor = view.backgroundColor
        }
        
        let blurEffect = UIBlurEffect(style: menuBlurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clear
        if let tableViewController = forMenu.topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, at: 0)
        }
    }
    
    fileprivate func removeMenuBlurForMenu(_ forMenu: UISideMenuNavigationController?) {
        guard let forMenu = forMenu,
            let originalMenuBackgroundColor = forMenu.originalMenuBackgroundColor,
            let view = forMenu.topViewController?.view else {
                return
        }
        
        view.backgroundColor = originalMenuBackgroundColor
        forMenu.originalMenuBackgroundColor = nil
        
        if let tableViewController = forMenu.topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = nil
            tableViewController.tableView.separatorEffect = nil
            tableViewController.tableView.reloadData()
        } else if let blurView = view.subviews[0] as? UIVisualEffectView {
            blurView.removeFromSuperview()
        }
    }
    
    /**
     Adds screen edge gestures to a view to present a menu.
     
     - Parameter toView: The view to add gestures to.
     - Parameter forMenu: The menu (left or right) you want to add a gesture for. If unspecified, gestures will be added for both sides.
 
     - Returns: The array of screen edge gestures added to `toView`.
     */
    @discardableResult open func menuAddScreenEdgePanGesturesToPresent(toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer] {
        var array = [UIScreenEdgePanGestureRecognizer]()
        
        let newScreenEdgeGesture = { () -> UIScreenEdgePanGestureRecognizer in
            let screenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            screenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(screenEdgeGestureRecognizer)
            array.append(screenEdgeGestureRecognizer)
            return screenEdgeGestureRecognizer
        }
        
        if forMenu != .right {
            let leftScreenEdgeGestureRecognizer = newScreenEdgeGesture()
            leftScreenEdgeGestureRecognizer.addTarget(transition, action:#selector(SideMenuTransition.handlePresentMenuLeftScreenEdge(_:)))
            leftScreenEdgeGestureRecognizer.edges = .left
            
            #if !STFU_SIDEMENU
            if menuLeftNavigationController == nil {
                print("SideMenu Warning: menuAddScreenEdgePanGesturesToPresent was called before menuLeftNavigationController was set. The gesture will not work without a menu. Use menuAddScreenEdgePanGesturesToPresent(toView:forMenu:) to add gestures for only one menu.")
            }
            #endif
        }
        
        if forMenu != .left {
            let rightScreenEdgeGestureRecognizer = newScreenEdgeGesture()
            rightScreenEdgeGestureRecognizer.addTarget(transition, action:#selector(SideMenuTransition.handlePresentMenuRightScreenEdge(_:)))
            rightScreenEdgeGestureRecognizer.edges = .right
            
            #if !STFU_SIDEMENU
            if menuRightNavigationController == nil {
                print("SideMenu Warning: menuAddScreenEdgePanGesturesToPresent was called before menuRightNavigationController was set. The gesture will not work without a menu. Use menuAddScreenEdgePanGesturesToPresent(toView:forMenu:) to add gestures for only one menu.")
            }
            #endif
        }
        
        return array
    }
    
    /**
     Adds a pan edge gesture to a view to present menus.
     
     - Parameter toView: The view to add a pan gesture to.
     
     - Returns: The pan gesture added to `toView`.
     */
    @discardableResult open func menuAddPanGestureToPresent(toView: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(transition, action:#selector(SideMenuTransition.handlePresentMenuPan(_:)))
        toView.addGestureRecognizer(panGestureRecognizer)
        
        if menuLeftNavigationController ?? menuRightNavigationController == nil {
            print("SideMenu Warning: menuAddPanGestureToPresent called before menuLeftNavigationController or menuRightNavigationController have been defined. Gestures will not work without a menu.")
        }
        
        return panGestureRecognizer
    }
}
