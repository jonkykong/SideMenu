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

open class SideMenuManager : NSObject {
    
    public enum MenuPushStyle : Int {
        case defaultBehavior,
        popWhenPossible,
        replace,
        preserve,
        preserveAndHideBackButton,
        subMenu
    }
    
    public enum MenuPresentMode : Int {
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
     Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width or 240 points, whichever is smaller.
     
     Note that each menu's width can be overridden using the `menuWidth` property on any `UISideMenuNavigationController` instance.
     */
    open static var menuWidth: CGFloat = min(round(min((appScreenRect.width), (appScreenRect.height)) * 0.75), 240)
    
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
    
    /// -Warning: Deprecated. Use `menuPushStyle = .subMenu` instead.
    @available(*, deprecated, renamed: "menuPushStyle", message: "Use `menuPushStyle = .subMenu` instead.")
    open static var menuAllowSubmenus: Bool {
        get {
            return menuPushStyle == .subMenu
        }
        set {
            if newValue {
                menuPushStyle = .subMenu
            }
        }
    }
    
    /// -Warning: Deprecated. Use `menuPushStyle = .popWhenPossible` instead.
    @available(*, deprecated, renamed: "menuPushStyle", message: "Use `menuPushStyle = .popWhenPossible` instead.")
    open static var menuAllowPopIfPossible: Bool {
        get {
            return menuPushStyle == .popWhenPossible
        }
        set {
            if newValue {
                menuPushStyle = .popWhenPossible
            }
        }
    }
    
    /// -Warning: Deprecated. Use `menuPushStyle = .replace` instead.
    @available(*, deprecated, renamed: "menuPushStyle", message: "Use `menuPushStyle = .replace` instead.")
    open static var menuReplaceOnPush: Bool {
        get {
            return menuPushStyle == .replace
        }
        set {
            if newValue {
                menuPushStyle = .replace
            }
        }
    }
    
    /// -Warning: Deprecated. Use `menuAnimationTransformScaleFactor` instead.
    @available(*, deprecated, renamed: "menuAnimationTransformScaleFactor")
    open static var menuAnimationShrinkStrength: CGFloat {
        get {
            return menuAnimationTransformScaleFactor
        }
        set {
            menuAnimationTransformScaleFactor = newValue
        }
    }
    
    // prevent instantiation
    fileprivate override init() {}
    
    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.
     
     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    open static var menuBlurEffectStyle: UIBlurEffectStyle? {
        didSet {
            if oldValue != menuBlurEffectStyle {
                updateMenuBlurIfNecessary()
            }
        }
    }
    
    /// The left menu.
    open static var menuLeftNavigationController: UISideMenuNavigationController? {
        willSet {
            if menuLeftNavigationController?.presentingViewController == nil {
                removeMenuBlurForMenu(menuLeftNavigationController)
            }
        }
        didSet {
            guard oldValue?.presentingViewController == nil else {
                print("SideMenu Warning: menuLeftNavigationController cannot be modified while it's presented.")
                menuLeftNavigationController = oldValue
                return
            }
            setupNavigationController(menuLeftNavigationController, leftSide: true)
        }
    }
    
    /// The right menu.
    open static var menuRightNavigationController: UISideMenuNavigationController? {
        willSet {
            if menuRightNavigationController?.presentingViewController == nil {
                removeMenuBlurForMenu(menuRightNavigationController)
            }
        }
        didSet {
            guard oldValue?.presentingViewController == nil else {
                print("SideMenu Warning: menuRightNavigationController cannot be modified while it's presented.")
                menuRightNavigationController = oldValue
                return
            }
            setupNavigationController(menuRightNavigationController, leftSide: false)
        }
    }
    
    /// The left menu swipe to dismiss gesture.
    open static weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
        didSet {
            oldValue?.view?.removeGestureRecognizer(oldValue!)
            setupGesture(gesture: menuLeftSwipeToDismissGesture)
        }
    }
    
    /// The right menu swipe to dismiss gesture.
    open static weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
        didSet {
            oldValue?.view?.removeGestureRecognizer(oldValue!)
            setupGesture(gesture: menuRightSwipeToDismissGesture)
        }
    }
    
    fileprivate class func setupGesture(gesture: UIPanGestureRecognizer?) {
        guard let gesture = gesture else {
            return
        }
        
        gesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
    }
    
    fileprivate class func setupNavigationController(_ forMenu: UISideMenuNavigationController?, leftSide: Bool) {
        guard let forMenu = forMenu else {
            return
        }
        
        if menuEnableSwipeGestures {
            let exitPanGesture = UIPanGestureRecognizer()
            forMenu.view.addGestureRecognizer(exitPanGesture)
            if leftSide {
                menuLeftSwipeToDismissGesture = exitPanGesture
            } else {
                menuRightSwipeToDismissGesture = exitPanGesture
            }
        }
        forMenu.transitioningDelegate = SideMenuTransition.singleton
        forMenu.modalPresentationStyle = .overFullScreen
        forMenu.leftSide = leftSide
        updateMenuBlurIfNecessary()
    }
    
    /// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
    open static var menuEnableSwipeGestures: Bool = true {
        didSet {
            menuLeftSwipeToDismissGesture?.view?.removeGestureRecognizer(menuLeftSwipeToDismissGesture!)
            menuRightSwipeToDismissGesture?.view?.removeGestureRecognizer(menuRightSwipeToDismissGesture!)
            setupNavigationController(menuLeftNavigationController, leftSide: true)
            setupNavigationController(menuRightNavigationController, leftSide: false)
        }
    }
    
    fileprivate class func updateMenuBlurIfNecessary() {
        let menuBlurBlock = { (forMenu: UISideMenuNavigationController?) in
            if let forMenu = forMenu {
                setupMenuBlurForMenu(forMenu)
            }
        }
        
        menuBlurBlock(menuLeftNavigationController)
        menuBlurBlock(menuRightNavigationController)
    }
    
    fileprivate class func setupMenuBlurForMenu(_ forMenu: UISideMenuNavigationController?) {
        removeMenuBlurForMenu(forMenu)
        
        guard let forMenu = forMenu,
            let menuBlurEffectStyle = menuBlurEffectStyle,
            let view = forMenu.visibleViewController?.view
            , !UIAccessibilityIsReduceTransparencyEnabled() else {
                return
        }
        
        if forMenu.originalMenuBackgroundColor == nil {
            forMenu.originalMenuBackgroundColor = view.backgroundColor
        }
        
        let blurEffect = UIBlurEffect(style: menuBlurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clear
        if let tableViewController = forMenu.visibleViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, at: 0)
        }
    }
    
    fileprivate class func removeMenuBlurForMenu(_ forMenu: UISideMenuNavigationController?) {
        guard let forMenu = forMenu,
            let originalMenuBackgroundColor = forMenu.originalMenuBackgroundColor,
            let view = forMenu.visibleViewController?.view else {
                return
        }
        
        view.backgroundColor = originalMenuBackgroundColor
        forMenu.originalMenuBackgroundColor = nil
        
        if let tableViewController = forMenu.visibleViewController as? UITableViewController {
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
    @discardableResult open class func menuAddScreenEdgePanGesturesToPresent(toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer] {
        var array = [UIScreenEdgePanGestureRecognizer]()
        
        if forMenu != .right {
            let leftScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            leftScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuLeftScreenEdge(_:)))
            leftScreenEdgeGestureRecognizer.edges = .left
            leftScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(leftScreenEdgeGestureRecognizer)
            array.append(leftScreenEdgeGestureRecognizer)
            
            if SideMenuManager.menuLeftNavigationController == nil {
                print("SideMenu Warning: menuAddScreenEdgePanGesturesToPresent for the left side was called before menuLeftNavigationController has been defined. The gesture will not work without a menu.")
            }
        }
        
        if forMenu != .left {
            let rightScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            rightScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuRightScreenEdge(_:)))
            rightScreenEdgeGestureRecognizer.edges = .right
            rightScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(rightScreenEdgeGestureRecognizer)
            array.append(rightScreenEdgeGestureRecognizer)
            
            if SideMenuManager.menuRightNavigationController == nil {
                print("SideMenu Warning: menuAddScreenEdgePanGesturesToPresent for the right side was called before menuRightNavigationController has been defined. The gesture will not work without a menu.")
            }
        }
        
        return array
    }
    
    /**
     Adds a pan edge gesture to a view to present menus.
     
     - Parameter toView: The view to add a pan gesture to.
     
     - Returns: The pan gesture added to `toView`.
     */
    @discardableResult open class func menuAddPanGestureToPresent(toView: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuPan(_:)))
        toView.addGestureRecognizer(panGestureRecognizer)
        
        if SideMenuManager.menuLeftNavigationController ?? SideMenuManager.menuRightNavigationController == nil {
            print("SideMenu Warning: menuAddPanGestureToPresent called before menuLeftNavigationController or menuRightNavigationController have been defined. Gestures will not work without a menu.")
        }
        
        return panGestureRecognizer
    }
}
