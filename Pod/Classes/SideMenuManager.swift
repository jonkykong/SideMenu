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

    private static var originalLeftMenuBackgroundColor: UIColor?
    private static var originalRightMenuBackgroundColor: UIColor?

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
    public static var menuWidth: CGFloat = max(round(min(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * 0.75), 240)
    
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
            updateMenuBlurIfNecessary()
        }
    }
    
    /// The left menu.
    public static var menuLeftNavigationController: UISideMenuNavigationController? {
        willSet {
            if menuLeftNavigationController != nil {
                let originalBlurEffectStyle = menuBlurEffectStyle
                menuBlurEffectStyle = nil
                updateMenuBlurIfNecessary()
                menuBlurEffectStyle = originalBlurEffectStyle
            }
        }
        didSet {
            if let menuLeftNavigationController = menuLeftNavigationController {
                let exitPanGesture = UIPanGestureRecognizer()
                exitPanGesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
                menuLeftNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuLeftNavigationController.transitioningDelegate = SideMenuTransition.singleton
                menuLeftNavigationController.modalPresentationStyle = .OverFullScreen
                if !menuLeftNavigationController.leftSide {
                    menuLeftNavigationController.leftSide = true
                }
                menuLeftSwipeToDismissGesture = exitPanGesture
                updateMenuBlurIfNecessary()
            }
        }
    }
    
    /// The right menu.
    public static var menuRightNavigationController: UISideMenuNavigationController? {
        willSet {
            if menuRightNavigationController != nil {
                let originalBlurEffectStyle = menuBlurEffectStyle
                menuBlurEffectStyle = nil
                updateMenuBlurIfNecessary()
                menuBlurEffectStyle = originalBlurEffectStyle
            }
        }
        didSet {
            if let menuRightNavigationController = menuRightNavigationController {
                let exitPanGesture = UIPanGestureRecognizer()
                exitPanGesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
                menuRightNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuRightNavigationController.transitioningDelegate = SideMenuTransition.singleton
                menuRightNavigationController.modalPresentationStyle = .OverFullScreen
                if menuRightNavigationController.leftSide {
                    menuRightNavigationController.leftSide = false
                }
                menuRightSwipeToDismissGesture = exitPanGesture
                updateMenuBlurIfNecessary()
            }
        }
    }
    
    private class func updateMenuBlurIfNecessary() {
        if let menuLeftNavigationController = menuLeftNavigationController, let view = menuLeftNavigationController.visibleViewController?.view {
            if !UIAccessibilityIsReduceTransparencyEnabled() && menuBlurEffectStyle != nil {
                if originalLeftMenuBackgroundColor == nil {
                    originalLeftMenuBackgroundColor = view.backgroundColor
                }
                setupMenuBlurForMenu(menuLeftNavigationController)
            } else if originalLeftMenuBackgroundColor != nil {
                removeMenuBlurForMenu(menuLeftNavigationController)
                view.backgroundColor = originalLeftMenuBackgroundColor!
                originalLeftMenuBackgroundColor = nil
            }
        }
        
        if let menuRightNavigationController = menuRightNavigationController, let view = menuRightNavigationController.visibleViewController?.view {
            if !UIAccessibilityIsReduceTransparencyEnabled() && menuBlurEffectStyle != nil {
                if originalRightMenuBackgroundColor == nil {
                    originalRightMenuBackgroundColor = view.backgroundColor
                }
                setupMenuBlurForMenu(menuRightNavigationController)
            } else if originalRightMenuBackgroundColor != nil {
                removeMenuBlurForMenu(menuRightNavigationController)
                view.backgroundColor = originalRightMenuBackgroundColor!
                originalRightMenuBackgroundColor = nil
            }
        }
    }
    
    private class func setupMenuBlurForMenu(forMenu: UINavigationController) {
        removeMenuBlurForMenu(forMenu)
        if let tableViewController = forMenu.visibleViewController as? UITableViewController {
            tableViewController.tableView.backgroundColor = UIColor.clearColor()
            
            let blurEffect = UIBlurEffect(style: menuBlurEffectStyle!)
            tableViewController.tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else if let viewController = forMenu.visibleViewController {
            viewController.view.backgroundColor = UIColor.clearColor()
            
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: menuBlurEffectStyle!))
            blurView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            blurView.frame = viewController.view.bounds
            
            viewController.view.insertSubview(blurView, atIndex: 0)
        }
    }
    
    private class func removeMenuBlurForMenu(forMenu: UINavigationController) {
        if let tableViewController = forMenu.visibleViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = nil
            tableViewController.tableView.separatorEffect = nil
            tableViewController.tableView.reloadData()
        } else if let viewController = forMenu.visibleViewController {
            if let blurView = viewController.view.subviews[0] as? UIVisualEffectView {
                blurView.removeFromSuperview()
            }
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