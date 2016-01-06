//
//  SideMenuManager.swift
//
//  Created by Jon Kent on 12/6/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

/* Example usage:
    SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewControllerWithIdentifier("UILeftMenuNavigationController") as? UILeftMenuNavigationController
    SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewControllerWithIdentifier("UIRightMenuNavigationController") as? UIRightMenuNavigationController
    SideMenuManager.menuAddPanToPresentGesture(toView: self.navigationController!.navigationBar)
    SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
*/

public class UISideMenuNavigationController: UINavigationController {
    
    @IBInspectable public var leftSide:Bool = false {
        didSet {
            if isViewLoaded() { // suppress warnings
                didSetSide()
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        didSetSide()
    }

    private func didSetSide() {
        if leftSide {
            SideMenuManager.menuLeftNavigationController = self
        } else {
            SideMenuManager.menuRightNavigationController = self
        }
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // we had presented a view before, so lets dismiss ourselves as already acted upon
        if view.hidden {
            SideMenuManager.hideMenuComplete()
            dismissViewControllerAnimated(false, completion: { () -> Void in
                self.view.hidden = false
            })
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // when presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if !isBeingDismissed() {
            if let mainView = presentingViewController?.view {
                switch SideMenuManager.menuPresentMode {
                case .ViewSlideOut:
                    mainView.superview?.insertSubview(view, belowSubview: mainView)
                case .MenuSlideIn, .MenuDissolveIn:
                    mainView.superview?.insertSubview(view, aboveSubview: SideMenuManager.tapView)
                }
            }
        }
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // we're presenting a view controller from the menu, so we need to hide the menu so it isn't  g when the presented view is dismissed.
        if !isBeingDismissed() {
            view.hidden = true
            SideMenuManager.hideMenuStart()
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // don't bother resizing if the view isn't visible
        if view.hidden {
            return
        }
        
        SideMenuManager.statusBarView?.hidden = true
        coordinator.animateAlongsideTransition({ (context) -> Void in
            SideMenuManager.presentMenuStart(forSize: size)
            }) { (context) -> Void in
                SideMenuManager.statusBarView?.hidden = false
        }
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let menuViewController: UINavigationController = SideMenuManager.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                presentingViewController.prepareForSegue(segue, sender: sender)
        }
    }
    
    override public func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if let menuViewController: UINavigationController = SideMenuManager.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                return presentingViewController.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
        
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    override public func pushViewController(viewController: UIViewController, animated: Bool) {
        if let menuViewController: UINavigationController = SideMenuManager.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController {
            if let presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                
                // to avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
                // is dismissed after showing the appropriate screen
                CATransaction.begin()
                CATransaction.setCompletionBlock( { () -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.visibleViewController?.viewWillAppear(false) // Hack: force selection to get cleared on UITableViewControllers when reappearing using custom transitions
                })
                
                UIView.animateWithDuration(SideMenuManager.menuAnimationDismissDuration, animations: { () -> Void in
                    SideMenuManager.hideMenuStart()
                })
                
                if SideMenuManager.menuAllowPopIfPossible {
                    for subViewController in presentingViewController.viewControllers {
                        if subViewController.dynamicType == viewController.dynamicType {
                            presentingViewController.popToViewController(subViewController, animated: animated)
                            CATransaction.commit()
                            return
                        }
                    }
                }
                if !SideMenuManager.menuAllowPushOfSameClassTwice {
                    if presentingViewController.viewControllers.last?.dynamicType == viewController.dynamicType {
                        CATransaction.commit()
                        return
                    }
                }
                
                presentingViewController.pushViewController(viewController, animated: animated)
                CATransaction.commit()
            } else {
                menuViewController.presentViewController(viewController, animated: animated, completion: nil)
                print("Warning: attempted to push a ViewController from a ViewController that doesn't have a NavigationController. It will be presented it instead.")
            }
        }
    }
}

public class SideMenuManager: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    public enum MenuPresentMode {
        case MenuSlideIn
        case ViewSlideOut
        case MenuDissolveIn
    }
    
    private static var presenting = false
    private static var interactive = false
    private static var presentDirection: UIRectEdge = .Left;
    private static weak var tapView: UIView!
    private static weak var statusBarView: UIView?
    private static let singleton = SideMenuManager()
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
    
    // prevent instantiation
    private override init() {}
    
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
                exitPanGesture.addTarget(self, action:"handleHideMenuPan:")
                menuLeftNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuLeftNavigationController.transitioningDelegate = singleton
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
                exitPanGesture.addTarget(self, action:"handleHideMenuPan:")
                menuRightNavigationController.view.addGestureRecognizer(exitPanGesture)
                menuRightNavigationController.transitioningDelegate = singleton
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
    
    private static var viewControllerForPresentedMenu: UIViewController? {
        get {
            return menuLeftNavigationController?.presentingViewController != nil ? menuLeftNavigationController?.presentingViewController : menuRightNavigationController?.presentingViewController
        }
    }
    
    public class func menuAddScreenEdgePanGesturesToPresent(toView toView: UIView, forMenu:UIRectEdge? = nil) -> [UIScreenEdgePanGestureRecognizer] {
        
        var array = [UIScreenEdgePanGestureRecognizer]()
        
        if forMenu != .Right {
            let leftScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            leftScreenEdgeGestureRecognizer.addTarget(self, action:"handlePresentMenuPan:")
            leftScreenEdgeGestureRecognizer.edges = .Left
            leftScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(leftScreenEdgeGestureRecognizer)
            array.append(leftScreenEdgeGestureRecognizer)
        }
        
        if forMenu != .Left {
            let rightScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
            rightScreenEdgeGestureRecognizer.addTarget(self, action:"handlePresentMenuPan:")
            rightScreenEdgeGestureRecognizer.edges = .Right
            rightScreenEdgeGestureRecognizer.cancelsTouchesInView = true
            toView.addGestureRecognizer(rightScreenEdgeGestureRecognizer)
            array.append(rightScreenEdgeGestureRecognizer)
        }
        
        return array
    }
    
    public class func menuAddPanGestureToPresent(toView toView: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action:"handlePresentMenuPan:")
        toView.addGestureRecognizer(panGestureRecognizer)
        
        return panGestureRecognizer
    }
    
    class func handlePresentMenuPan(pan: UIPanGestureRecognizer) {
        // how much distance have we panned in reference to the parent view?
        if let view = viewControllerForPresentedMenu != nil ? viewControllerForPresentedMenu?.view : pan.view {
            let transform = view.transform
            view.transform = CGAffineTransformIdentity
            let translation = pan.translationInView(pan.view!)
            view.transform = transform
            
            // do some math to translate this to a percentage based value
            if !interactive {
                if translation.x == 0 {
                    return // not sure which way the user is swiping yet, so do nothing
                }
            
                if let edge = pan as? UIScreenEdgePanGestureRecognizer {
                    presentDirection = edge.edges == .Left ? .Left : .Right
                } else {
                    presentDirection = translation.x > 0 ? .Left : .Right
                }
                
                if let menuViewController: UINavigationController = presentDirection == .Left ? menuLeftNavigationController : menuRightNavigationController {
                    interactive = true
                    if let visibleViewController = visibleViewController() {
                        visibleViewController.presentViewController(menuViewController, animated: true, completion: nil)
                    }
                }
            }
        
            let direction:CGFloat = presentDirection == .Left ? 1 : -1
            let distance = translation.x / menuWidth
            // now lets deal with different states that the gesture recognizer sends
            switch (pan.state) {
            case .Began, .Changed:
                if pan is UIScreenEdgePanGestureRecognizer {
                    singleton.updateInteractiveTransition(min(distance * direction, 1))
                } else if distance > 0 && presentDirection == .Right && menuLeftNavigationController != nil {
                    presentDirection = .Left
                    singleton.cancelInteractiveTransition()
                    viewControllerForPresentedMenu?.presentViewController(menuLeftNavigationController!, animated: true, completion: nil)
                } else if distance < 0 && presentDirection == .Left && menuRightNavigationController != nil {
                    presentDirection = .Right
                    singleton.cancelInteractiveTransition()
                    viewControllerForPresentedMenu?.presentViewController(menuRightNavigationController!, animated: true, completion: nil)
                } else {
                    singleton.updateInteractiveTransition(min(distance * direction, 1))
                }
            default:
                interactive = false
                view.transform = CGAffineTransformIdentity
                let velocity = pan.velocityInView(pan.view!).x * direction
                view.transform = transform
                if velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5 {
                    singleton.finishInteractiveTransition()
                } else {
                    singleton.cancelInteractiveTransition()
                }
            }
        }
    }
    
    class func handleHideMenuPan(pan: UIPanGestureRecognizer) {
        
        let translation = pan.translationInView(pan.view!)
        let direction:CGFloat = presentDirection == .Left ? -1 : 1
        let distance = translation.x / menuWidth * direction
        
        switch (pan.state) {
            
        case .Began:
            interactive = true
            viewControllerForPresentedMenu?.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            singleton.updateInteractiveTransition(max(min(distance, 1), 0))
        default:
            interactive = false
            let velocity = pan.velocityInView(pan.view!).x * direction
            if velocity >= 100 || velocity >= -50 && distance >= 0.5 {
                singleton.finishInteractiveTransition()
            }
            else {
                singleton.cancelInteractiveTransition()
            }
        }
    }
    
    class func handleHideMenuTap(tap: UITapGestureRecognizer) {
        viewControllerForPresentedMenu?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private class func visibleViewController() -> UIViewController? {
        return getVisibleViewControllerFrom(UIApplication.sharedApplication().keyWindow?.rootViewController)
    }
    
    private class func getVisibleViewControllerFrom(viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return getVisibleViewControllerFrom(navigationController.visibleViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return getVisibleViewControllerFrom(tabBarController.selectedViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return getVisibleViewControllerFrom(presentedViewController)
        }
        
        return viewController
    }
    
    private class func hideMenuStart() {
        let mainViewController = viewControllerForPresentedMenu!
        let menuView = presentDirection == .Left ? menuLeftNavigationController!.view : menuRightNavigationController!.view
        menuView.transform = CGAffineTransformIdentity
        mainViewController.view.transform = CGAffineTransformIdentity
        mainViewController.view.alpha = 1
        tapView.frame = CGRectMake(0, 0, mainViewController.view.frame.width, mainViewController.view.frame.height)
        menuView.frame.origin.y = 0
        menuView.frame.size.width = menuWidth
        menuView.frame.size.height = mainViewController.view.frame.height
        statusBarView?.frame = UIApplication.sharedApplication().statusBarFrame
        statusBarView?.alpha = 0
        
        switch menuPresentMode {
            
        case .ViewSlideOut:
            menuView.alpha = 1 - menuAnimationFadeStrength
            menuView.frame.origin.x = presentDirection == .Left ? 0 : mainViewController.view.frame.width - menuWidth
            mainViewController.view.frame.origin.x = 0
            menuView.transform = CGAffineTransformMakeScale(menuAnimationShrinkStrength, menuAnimationShrinkStrength)
            
        case .MenuSlideIn:
            menuView.alpha = 1
            menuView.frame.origin.x = presentDirection == .Left ? -menuView.frame.width : mainViewController.view.frame.width
            
        case .MenuDissolveIn:
            menuView.alpha = 0
            menuView.frame.origin.x = presentDirection == .Left ? 0 : mainViewController.view.frame.width - menuWidth
            mainViewController.view.frame.origin.x = 0
        }
    }
    
    private class func hideMenuComplete() {
        let mainViewController = viewControllerForPresentedMenu!
        let menuView = presentDirection == .Left ? menuLeftNavigationController!.view : menuRightNavigationController!.view
        tapView.removeFromSuperview()
        statusBarView?.removeFromSuperview()
        mainViewController.view.motionEffects.removeAll()
        mainViewController.view.layer.shadowOpacity = 0
        menuView.layer.shadowOpacity = 0
        NSNotificationCenter.defaultCenter().removeObserver(singleton)
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.enabled = true
        }
    }
    
    private class func presentMenuStart(forSize size: CGSize = UIScreen.mainScreen().bounds.size) {
        let mainViewController = viewControllerForPresentedMenu!
        if let menuView = presentDirection == .Left ? menuLeftNavigationController?.view : menuRightNavigationController?.view {
            menuView.transform = CGAffineTransformIdentity
            mainViewController.view.transform = CGAffineTransformIdentity
            menuView.frame.size.width = menuWidth
            menuView.frame.size.height = size.height
            menuView.frame.origin.x = presentDirection == .Left ? 0 : size.width - menuWidth
            statusBarView?.frame = UIApplication.sharedApplication().statusBarFrame
            statusBarView?.alpha = 1
            
            switch menuPresentMode {
                
            case .ViewSlideOut:
                menuView.alpha = 1
                let direction:CGFloat = presentDirection == .Left ? 1 : -1
                mainViewController.view.frame.origin.x = direction * (menuView.frame.width)
                mainViewController.view.layer.shadowColor = menuShadowColor.CGColor
                mainViewController.view.layer.shadowRadius = menuShadowRadius
                mainViewController.view.layer.shadowOpacity = menuShadowOpacity
                mainViewController.view.layer.shadowOffset = CGSizeMake(0, 0)
                
            case .MenuSlideIn, .MenuDissolveIn:
                menuView.alpha = 1
                menuView.layer.shadowColor = menuShadowColor.CGColor
                menuView.layer.shadowRadius = menuShadowRadius
                menuView.layer.shadowOpacity = menuShadowOpacity
                menuView.layer.shadowOffset = CGSizeMake(0, 0)
                mainViewController.view.frame = CGRectMake(0, 0, size.width, size.height)
                mainViewController.view.transform = CGAffineTransformMakeScale(menuAnimationShrinkStrength, menuAnimationShrinkStrength)
                mainViewController.view.alpha = 1 - menuAnimationFadeStrength
            }
        }
    }
    
    private class func presentMenuComplete() {
        let mainViewController = viewControllerForPresentedMenu!
        switch menuPresentMode {
        case .MenuSlideIn, .MenuDissolveIn:
            if menuParallaxStrength != 0 {
                let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
                horizontal.minimumRelativeValue = -menuParallaxStrength
                horizontal.maximumRelativeValue = menuParallaxStrength
                
                let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
                vertical.minimumRelativeValue = -menuParallaxStrength
                vertical.maximumRelativeValue = menuParallaxStrength
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [horizontal, vertical]
                mainViewController.view.addMotionEffect(group)
            }
        case .ViewSlideOut: break;
        }
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.enabled = false
        }
    }
    
    // MARK: UIViewControllerAnimatedTransitioning protocol methods
    
    // animate a change from one viewcontroller to another
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let statusBarStyle = SideMenuManager.visibleViewController()?.preferredStatusBarStyle()
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView()!
        if let menuBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
            container.backgroundColor = menuBackgroundColor
        }
        
        // create a tuple of our screens
        let screens : (from:UIViewController, to:UIViewController) = (transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!, transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!)
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let menuViewController = (!SideMenuManager.presenting ? screens.from : screens.to)
        let topViewController = !SideMenuManager.presenting ? screens.to : screens.from
        
        let menuView = menuViewController.view
        let topView = topViewController.view
        
        // prepare menu items to slide in
        if SideMenuManager.presenting {
            let tapView = UIView()
            tapView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.addTarget(SideMenuManager.self, action:"handleHideMenuPan:")
            let exitTapGesture = UITapGestureRecognizer()
            exitTapGesture.addTarget(SideMenuManager.self, action: "handleHideMenuTap:")
            tapView.addGestureRecognizer(exitPanGesture)
            tapView.addGestureRecognizer(exitTapGesture)
            
            // add the both views to our view controller
            switch SideMenuManager.menuPresentMode {
            case .ViewSlideOut:
                container.addSubview(menuView)
                container.addSubview(topView)
                topView.addSubview(tapView)
            case .MenuSlideIn, .MenuDissolveIn:
                container.addSubview(topView)
                container.addSubview(tapView)
                container.addSubview(menuView)
            }
            
            if SideMenuManager.menuFadeStatusBar {
                let blackBar = UIView()
                if let menuShrinkBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
                    blackBar.backgroundColor = menuShrinkBackgroundColor
                } else {
                    blackBar.backgroundColor = UIColor.blackColor()
                }
                blackBar.userInteractionEnabled = false
                container.addSubview(blackBar)
                SideMenuManager.statusBarView = blackBar
            }
            SideMenuManager.tapView = tapView
            
            SideMenuManager.hideMenuStart() // offstage for interactive
            
            NSNotificationCenter.defaultCenter().addObserver(SideMenuManager.singleton, selector:"applicationDidEnterBackgroundNotification", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        }
        
        // perform the animation!
        let duration = transitionDuration(transitionContext)
        let options: UIViewAnimationOptions = SideMenuManager.interactive ? .CurveLinear : .CurveEaseInOut
        UIView.animateWithDuration(duration, delay: 0, options: options, animations: { () -> Void in
            if SideMenuManager.presenting {
                SideMenuManager.presentMenuStart() // onstage items: slide in
            }
            else {
                SideMenuManager.hideMenuStart()
            }
            }) { (finished) -> Void in
                if SideMenuManager.visibleViewController()?.preferredStatusBarStyle() != statusBarStyle {
                    print("Warning: do not change the status bar style while using custom transitions or you risk transitions not properly completing and locking up the UI. See http://www.openradar.me/21961293")
                }
                // tell our transitionContext object that we've finished animating
                if transitionContext.transitionWasCancelled() {
                    if SideMenuManager.presenting {
                        SideMenuManager.hideMenuComplete()
                    }
                    transitionContext.completeTransition(false)
                } else {
                    if SideMenuManager.presenting {
                        SideMenuManager.presentMenuComplete()
                        transitionContext.completeTransition(true)
                        switch SideMenuManager.menuPresentMode {
                        case .ViewSlideOut:
                            container.addSubview(topView)
                        case .MenuSlideIn, .MenuDissolveIn:
                            container.insertSubview(topView, atIndex: 0)
                        }
                        if let statusBarView = SideMenuManager.statusBarView {
                            container.bringSubviewToFront(statusBarView)
                        }
                    } else {
                        SideMenuManager.hideMenuComplete()
                        transitionContext.completeTransition(true)
                        menuView.removeFromSuperview()
                    }
                }
        }
    }
    
    // return how many seconds the transiton animation will take
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return SideMenuManager.presenting ? SideMenuManager.menuAnimationPresentDuration : SideMenuManager.menuAnimationDismissDuration
    }
    
    // MARK: UIViewControllerTransitioningDelegate protocol methods
    
    // return the animataor when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SideMenuManager.presenting = true
        SideMenuManager.presentDirection = presented == SideMenuManager.menuLeftNavigationController ? .Left : .Right
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SideMenuManager.presenting = false
        return self
    }
    
    public func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if our interactive flag is true, return the transition manager object
        // otherwise return nil
        return SideMenuManager.interactive ? SideMenuManager.singleton : nil
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return SideMenuManager.interactive ? SideMenuManager.singleton : nil
    }
    
    func applicationDidEnterBackgroundNotification() {
        if let menuViewController: UINavigationController = SideMenuManager.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController {
            SideMenuManager.hideMenuStart()
            SideMenuManager.hideMenuComplete()
            menuViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }

}

public class UITableViewVibrantCell: UITableViewCell {
    
    private var vibrancyView:UIVisualEffectView = UIVisualEffectView()
    private var vibrancySelectedBackgroundView:UIVisualEffectView = UIVisualEffectView()
    private var defaultSelectedBackgroundView:UIView?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        vibrancyView.frame = bounds
        vibrancyView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        for view in subviews {
            vibrancyView.contentView.addSubview(view)
        }
        addSubview(vibrancyView)
        
        let blurSelectionEffect = UIBlurEffect(style: .Light)
        vibrancySelectedBackgroundView.effect = blurSelectionEffect
        defaultSelectedBackgroundView = selectedBackgroundView
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() && SideMenuManager.menuBlurEffectStyle != nil {
            let blurEffect = UIBlurEffect(style: SideMenuManager.menuBlurEffectStyle!)
            vibrancyView.effect = UIVibrancyEffect(forBlurEffect: blurEffect)
            
            if selectedBackgroundView != nil && selectedBackgroundView != vibrancySelectedBackgroundView {
                vibrancySelectedBackgroundView.contentView.addSubview(selectedBackgroundView!)
                selectedBackgroundView = vibrancySelectedBackgroundView
            }
        } else {
            vibrancyView.effect = nil
            selectedBackgroundView = defaultSelectedBackgroundView
        }
    }
}