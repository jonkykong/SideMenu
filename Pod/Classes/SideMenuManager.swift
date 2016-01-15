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
        case MenuDissolveIn
    }

    private static var originalLeftMenuBackgroundColor: UIColor?
    private static var originalRightMenuBackgroundColor: UIColor?
    
    public static var menuPresentMode:MenuPresentMode = .ViewSlideOut
    public static var menuAllowPushOfSameClassTwice = true
    public static var menuAllowPopIfPossible = false
    public static var menuWidth: CGFloat = max(round(min(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * 0.75), 240)
    public static var menuAnimationPresentDuration = 0.35
    public static var menuAnimationDismissDuration = 0.35
    public static var menuAnimationFadeStrength: CGFloat = 0
    public static var menuAnimationShrinkStrength: CGFloat = 1
    public static var menuAnimationBackgroundColor: UIColor?
    public static var menuShadowOpacity: Float = 0.5
    public static var menuShadowColor = UIColor.blackColor()
    public static var menuShadowRadius: CGFloat = 5
    public static weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer?
    public static weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer?
    public static var menuParallaxStrength: Int = 0
    public static var menuFadeStatusBar = true
    
    // Note: if you want cells in a UITableViewController menu to look good, make them a subclass of UITableViewVibrantCell!
    public static var menuBlurEffectStyle: UIBlurEffectStyle? {
        didSet {
            updateMenuBlurIfNecessary()
        }
    }
    
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
                exitPanGesture.addTarget(SideMenuTransition.self, action:"handleHideMenuPan:")
                menuLeftNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuLeftNavigationController.transitioningDelegate = SideMenuTransition.singleton
                menuLeftNavigationController.modalPresentationStyle = .OverFullScreen
                menuLeftSwipeToDismissGesture = exitPanGesture
                updateMenuBlurIfNecessary()
            }
        }
    }
    
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
                exitPanGesture.addTarget(SideMenuTransition.self, action:"handleHideMenuPan:")
                menuRightNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuRightNavigationController.transitioningDelegate = SideMenuTransition.singleton
                menuRightNavigationController.modalPresentationStyle = .OverFullScreen
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
    
    public class func menuAddScreenEdgePanGesturesToPresent(toView toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer] {
        
        var array = [UIScreenEdgePanGestureRecognizer]()
        
        if forMenu != .Right {
            let leftScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            leftScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:"handlePresentMenuPan:")
            leftScreenEdgeGestureRecognizer.edges = .Left
            leftScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(leftScreenEdgeGestureRecognizer)
            array.append(leftScreenEdgeGestureRecognizer)
        }
        
        if forMenu != .Left {
            let rightScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            rightScreenEdgeGestureRecognizer.addTarget(SideMenuTransition.self, action:"handlePresentMenuPan:")
            rightScreenEdgeGestureRecognizer.edges = .Right
            rightScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(rightScreenEdgeGestureRecognizer)
            array.append(rightScreenEdgeGestureRecognizer)
        }
        
        return array
    }
    
    public class func menuAddPanGestureToPresent(toView toView: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(SideMenuTransition.self, action:"handlePresentMenuPan:")
        toView.addGestureRecognizer(panGestureRecognizer)
        
        return panGestureRecognizer
    }
}