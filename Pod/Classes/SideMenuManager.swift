//
//  SideMenuManager.swift
//
//  Created by Jon Kent on 12/6/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

/* Example usage:
    // Define the menus
    SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewControllerWithIdentifier("LeftMenuNavigationController") as? UISideMenuNavigationController
    SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewControllerWithIdentifier("RightMenuNavigationController") as? UISideMenuNavigationController

    // Enable gestures. The left and/or right menus must be set up above for these to work.
    // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
    SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
    SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
*/

public class SideMenuManager {
    
    public enum MenuPresentMode {
        case MenuSlideIn
        case ViewSlideOut
        case ViewSlideInOut
        case MenuDissolveIn
    }
    
    // Bounds which has been allocated for the app on the whole device screen
    internal static var appScreenRect: CGRect {
        let appWindowRect = UIApplication.sharedApplication().keyWindow?.bounds ?? UIWindow().bounds
        return appWindowRect
    }

    /**
     The presentation mode of the menu.
     
     There are four modes in MenuPresentMode:
     - MenuSlideIn: Menu slides in over of the existing view.
     - ViewSlideOut: The existing view slides out to reveal the menu.
     - ViewSlideInOut: The existing view slides out while the menu slides in.
     - MenuDissolveIn: The menu dissolves in over the existing view controller.
     */
    public static var menuPresentMode: MenuPresentMode = .ViewSlideOut
    
    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    public static var menuAllowPushOfSameClassTwice = true
    
    /// Pops to any view controller already in the navigation stack instead of the view controller being pushed if they share the same class. Defaults to false.
    public static var menuAllowPopIfPossible = false
    
    /// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width.
    public static var menuWidth: CGFloat = max(round(min((appScreenRect.width), (appScreenRect.height)) * 0.75), 240)
    
    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    public static var menuAnimationPresentDuration = 0.35
    
    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    public static var menuAnimationDismissDuration = 0.35
    
    /// Amount to fade the existing view controller when the menu is presented. Default is 0 for no fade. Set to 1 to fade completely.
    public static var menuAnimationFadeStrength: CGFloat = 0
    
    /// The amount to scale the existing view controller or the menu view controller depending on the `menuPresentMode`. Default is 1 for no scaling. Less than 1 will shrink, greater than 1 will grow.
    public static var menuAnimationTransformScaleFactor: CGFloat = 1
    
    /// The background color behind menu animations. Depending on the animation settings this may not be visible. If `menuFadeStatusBar` is true, this color is used to fade it. Default is black.
    public static var menuAnimationBackgroundColor: UIColor?
    
    /// The shadow opacity around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 0.5 for 50% opacity.
    public static var menuShadowOpacity: Float = 0.5
    
    /// The shadow color around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is black.
    public static var menuShadowColor = UIColor.blackColor()
    
    /// The radius of the shadow around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 5.
    public static var menuShadowRadius: CGFloat = 5
    
    /// The left menu swipe to dismiss gesture.
    public static weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer?
    
    /// The right menu swipe to dismiss gesture.
    public static weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer?
    
    /// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
    public static var menuParallaxStrength: Int = 0
    
    /// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
    public static var menuFadeStatusBar = true
    
    /// - Warning: Deprecated. Use `menuAnimationTransformScaleFactor` instead.
    @available(*, deprecated, renamed="menuAnimationTransformScaleFactor")
    public static var menuAnimationShrinkStrength: CGFloat {
        get {
            return menuAnimationTransformScaleFactor
        }
        set {
            menuAnimationTransformScaleFactor = newValue
        }
    }
    
    // prevent instantiation
    private init() {}
    
    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.
     
     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    public static var menuBlurEffectStyle: UIBlurEffectStyle? {
        didSet {
            if oldValue != menuBlurEffectStyle {
                updateMenuBlurIfNecessary()
            }
        }
    }
    
    /// The left menu.
    public static var menuLeftNavigationController: UISideMenuNavigationController? {
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
    public static var menuRightNavigationController: UISideMenuNavigationController? {
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
    
    private class func setupNavigationController(forMenu: UISideMenuNavigationController?, leftSide: Bool) {
        guard let forMenu = forMenu else {
            return
        }
        
        let exitPanGesture = UIPanGestureRecognizer()
        exitPanGesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
        forMenu.view.addGestureRecognizer(exitPanGesture)
        forMenu.transitioningDelegate = SideMenuTransition.singleton
        forMenu.modalPresentationStyle = .OverFullScreen
        forMenu.leftSide = leftSide
        if leftSide {
            menuLeftSwipeToDismissGesture = exitPanGesture
        } else {
            menuRightSwipeToDismissGesture = exitPanGesture
        }
        updateMenuBlurIfNecessary()
    }
    
    private class func updateMenuBlurIfNecessary() {
        let menuBlurBlock = { (forMenu: UISideMenuNavigationController?) in
            if let forMenu = forMenu {
                setupMenuBlurForMenu(forMenu)
            }
        }
        
        menuBlurBlock(menuLeftNavigationController)
        menuBlurBlock(menuRightNavigationController)
    }
    
    private class func setupMenuBlurForMenu(forMenu: UISideMenuNavigationController?) {
        removeMenuBlurForMenu(forMenu)
        
        guard let forMenu = forMenu,
            menuBlurEffectStyle = menuBlurEffectStyle,
            view = forMenu.visibleViewController?.view
            where !UIAccessibilityIsReduceTransparencyEnabled() else {
            return
        }
        
        if forMenu.originalMenuBackgroundColor == nil {
            forMenu.originalMenuBackgroundColor = view.backgroundColor
        }
        
        let blurEffect = UIBlurEffect(style: menuBlurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clearColor()
        if let tableViewController = forMenu.visibleViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, atIndex: 0)
        }
    }
    
    private class func removeMenuBlurForMenu(forMenu: UISideMenuNavigationController?) {
        guard let forMenu = forMenu,
            originalMenuBackgroundColor = forMenu.originalMenuBackgroundColor,
            view = forMenu.visibleViewController?.view else {
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
    public class func menuAddScreenEdgePanGesturesToPresent(toView toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer] {
        var array = [UIScreenEdgePanGestureRecognizer]()
        
        if forMenu != .Right {
            let leftScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            leftScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuLeftScreenEdge(_:)))
            leftScreenEdgeGestureRecognizer.edges = .Left
            leftScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(leftScreenEdgeGestureRecognizer)
            array.append(leftScreenEdgeGestureRecognizer)
        }
        
        if forMenu != .Left {
            let rightScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            rightScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuRightScreenEdge(_:)))
            rightScreenEdgeGestureRecognizer.edges = .Right
            rightScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(rightScreenEdgeGestureRecognizer)
            array.append(rightScreenEdgeGestureRecognizer)
        }
        
        return array
    }
    
    /**
     Adds a pan edge gesture to a view to present menus.
     
     - Parameter toView: The view to add a pan gesture to.
     
     - Returns: The pan gesture added to `toView`.
     */
    public class func menuAddPanGestureToPresent(toView toView: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handlePresentMenuPan(_:)))
        toView.addGestureRecognizer(panGestureRecognizer)
        
        return panGestureRecognizer
    }
}