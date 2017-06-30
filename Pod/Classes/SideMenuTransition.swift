//
//  SideMenuTransition.swift
//  Pods
//
//  Created by Jon Kent on 1/14/16.
//
//

import UIKit

open class SideMenuTransition: UIPercentDrivenInteractiveTransition {
    
    fileprivate var presenting = false
    fileprivate var interactive = false
    fileprivate static weak var originalSuperview: UIView?
    fileprivate static weak var activeGesture: UIGestureRecognizer?
    fileprivate static var switchMenus = false
    
    internal static let singleton = SideMenuTransition()
    internal static var presentDirection: UIRectEdge = .left
    internal static weak var tapView: UIView? {
        didSet {
            guard let tapView = tapView else {
                return
            }
            
            tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
            let exitTapGesture = UITapGestureRecognizer()
            exitTapGesture.addTarget(SideMenuTransition.self, action: #selector(SideMenuTransition.handleHideMenuTap(_:)))
            tapView.addGestureRecognizer(exitPanGesture)
            tapView.addGestureRecognizer(exitTapGesture)
        }
    }
    internal static weak var statusBarView: UIView? {
        didSet {
            guard let statusBarView = statusBarView else {
                return
            }
            
            if let menuShrinkBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
                statusBarView.backgroundColor = menuShrinkBackgroundColor
            } else {
                statusBarView.backgroundColor = UIColor.black
            }
            statusBarView.isUserInteractionEnabled = false
        }
    }
    
    // prevent instantiation
    fileprivate override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector:#selector(SideMenuTransition.handleNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SideMenuTransition.handleNotification), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(SideMenuTransition.singleton)
    }
    
    fileprivate class var presentingViewControllerForMenu: UIViewController? {
        get {
            return SideMenuManager.menuLeftNavigationController?.presentingViewController ?? SideMenuManager.menuRightNavigationController?.presentingViewController
        }
    }
    
    fileprivate class var viewControllerForMenu: UISideMenuNavigationController? {
        get {
            return SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController
        }
    }
    
    fileprivate class var visibleViewController: UIViewController? {
        get {
            return getVisibleViewControllerFromViewController(UIApplication.shared.keyWindow?.rootViewController)
        }
    }
    
    fileprivate class func getVisibleViewControllerFromViewController(_ viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return getVisibleViewControllerFromViewController(navigationController.visibleViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return getVisibleViewControllerFromViewController(tabBarController.selectedViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return getVisibleViewControllerFromViewController(presentedViewController)
        }
        
        return viewController
    }
    
    internal class func handlePresentMenuLeftScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        SideMenuTransition.presentDirection = .left
        handlePresentMenuPan(edge)
    }
    
    internal class func handlePresentMenuRightScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        SideMenuTransition.presentDirection = .right
        handlePresentMenuPan(edge)
    }
    
    internal class func handlePresentMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        } else if pan.state != .began && pan.state != .changed {
            activeGesture = nil
        }
        
        // how much distance have we panned in reference to the parent view?
        guard let view = presentingViewControllerForMenu?.view ?? pan.view else {
            return
        }
        
        let transform = view.transform
        view.transform = .identity
        let translation = pan.translation(in: pan.view!)
        view.transform = transform
        
        // do some math to translate this to a percentage based value
        if !singleton.interactive {
            if translation.x == 0 {
                return // not sure which way the user is swiping yet, so do nothing
            }
            
            if !(pan is UIScreenEdgePanGestureRecognizer) {
                SideMenuTransition.presentDirection = translation.x > 0 ? .left : .right
            }
            
            if let menuViewController = viewControllerForMenu, let visibleViewController = visibleViewController {
                singleton.interactive = true
                visibleViewController.present(menuViewController, animated: true, completion: nil)
            } else {
                return
            }
        }
        
        let direction: CGFloat = SideMenuTransition.presentDirection == .left ? 1 : -1
        let distance = translation.x / SideMenuManager.menuWidth
        // now lets deal with different states that the gesture recognizer sends
        switch (pan.state) {
        case .began, .changed:
            if pan is UIScreenEdgePanGestureRecognizer {
                singleton.update(min(distance * direction, 1))
            } else if distance > 0 && SideMenuTransition.presentDirection == .right && SideMenuManager.menuLeftNavigationController != nil {
                SideMenuTransition.presentDirection = .left
                switchMenus = true
                singleton.cancel()
            } else if distance < 0 && SideMenuTransition.presentDirection == .left && SideMenuManager.menuRightNavigationController != nil {
                SideMenuTransition.presentDirection = .right
                switchMenus = true
                singleton.cancel()
            } else {
                singleton.update(min(distance * direction, 1))
            }
        default:
            singleton.interactive = false
            view.transform = .identity
            let velocity = pan.velocity(in: pan.view!).x * direction
            view.transform = transform
            if velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && singleton.percentComplete > 1 - CGFloat.ulpOfOne {
                    singleton.update(0.9999)
                }
                singleton.finish()
            } else {
                singleton.cancel()
            }
        }
    }
    
    internal class func handleHideMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        }
        
        let translation = pan.translation(in: pan.view!)
        let direction:CGFloat = SideMenuTransition.presentDirection == .left ? -1 : 1
        let distance = translation.x / SideMenuManager.menuWidth * direction
        
        switch (pan.state) {
            
        case .began:
            singleton.interactive = true
            presentingViewControllerForMenu?.dismiss(animated: true, completion: nil)
        case .changed:
            singleton.update(max(min(distance, 1), 0))
        default:
            singleton.interactive = false
            let velocity = pan.velocity(in: pan.view!).x * direction
            if velocity >= 100 || velocity >= -50 && distance >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && singleton.percentComplete > 1 - CGFloat.ulpOfOne {
                    singleton.update(0.9999)
                }
                singleton.finish()
                activeGesture = nil
            } else {
                singleton.cancel()
                activeGesture = nil
            }
        }
    }
    
    internal class func handleHideMenuTap(_ tap: UITapGestureRecognizer) {
        presentingViewControllerForMenu?.dismiss(animated: true, completion: nil)
    }
    
    internal class func hideMenuStart() {
        guard let mainViewController = presentingViewControllerForMenu,
            let menuView = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController?.view : SideMenuManager.menuRightNavigationController?.view else {
                return
        }
      
        mainViewController.view.transform = .identity
        mainViewController.view.alpha = 1
        mainViewController.view.frame.origin.y = 0
        menuView.transform = .identity
        menuView.frame.origin.y = 0
        menuView.frame.size.width = SideMenuManager.menuWidth
        menuView.frame.size.height = mainViewController.view.frame.height // in case status bar height changed
        var statusBarFrame = UIApplication.shared.statusBarFrame
        let statusBarOffset = SideMenuManager.appScreenRect.size.height - mainViewController.view.frame.maxY
        // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
        // of view and set height to fill in remaining space.
        if statusBarOffset >= CGFloat.ulpOfOne {
            statusBarFrame.size.height = statusBarOffset
        }
        SideMenuTransition.statusBarView?.frame = statusBarFrame
        SideMenuTransition.statusBarView?.alpha = 0
        
        switch SideMenuManager.menuPresentMode {
            
        case .viewSlideOut:
            menuView.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
            menuView.transform = CGAffineTransform(scaleX: SideMenuManager.menuAnimationTransformScaleFactor, y: SideMenuManager.menuAnimationTransformScaleFactor)
            
        case .viewSlideInOut:
            menuView.alpha = 1
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? -menuView.frame.width : mainViewController.view.frame.width
            mainViewController.view.frame.origin.x = 0
            
        case .menuSlideIn:
            menuView.alpha = 1
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? -menuView.frame.width : mainViewController.view.frame.width
            
        case .menuDissolveIn:
            menuView.alpha = 0
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
        }
    }
    
    internal class func hideMenuComplete() {
        guard let mainViewController = presentingViewControllerForMenu,
            let menuView = viewControllerForMenu?.view else {
                return
        }

        SideMenuTransition.tapView?.removeFromSuperview()
        SideMenuTransition.statusBarView?.removeFromSuperview()
        mainViewController.view.motionEffects.removeAll()
        mainViewController.view.layer.shadowOpacity = 0
        menuView.layer.shadowOpacity = 0
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = true
        }
        if let originalSuperview = originalSuperview {
            originalSuperview.addSubview(mainViewController.view)
            let y = originalSuperview.bounds.height - mainViewController.view.frame.size.height
            mainViewController.view.frame.origin.y = max(y, 0)
        }
    }
    
    internal class func presentMenuStart() {
        guard let menuView = viewControllerForMenu?.view,
            let mainViewController = presentingViewControllerForMenu else {
                return
        }
        
        menuView.alpha = 1
        menuView.transform = .identity
        menuView.frame.size.width = SideMenuManager.menuWidth
        let size = SideMenuManager.appScreenRect.size
        menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : size.width - SideMenuManager.menuWidth
        mainViewController.view.transform = .identity
        mainViewController.view.frame.size.width = size.width
        let statusBarOffset = size.height - menuView.bounds.height
        mainViewController.view.bounds.size.height = size.height - max(statusBarOffset, 0)
        mainViewController.view.frame.origin.y = 0
        var statusBarFrame = UIApplication.shared.statusBarFrame
        // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
        // of view and set height to fill in remaining space.
        if statusBarOffset >= CGFloat.ulpOfOne {
            statusBarFrame.size.height = statusBarOffset
        }
        SideMenuTransition.tapView?.transform = .identity
        SideMenuTransition.tapView?.bounds = mainViewController.view.bounds
        SideMenuTransition.statusBarView?.frame = statusBarFrame
        SideMenuTransition.statusBarView?.alpha = 1
        
        switch SideMenuManager.menuPresentMode {
            
        case .viewSlideOut, .viewSlideInOut:
            mainViewController.view.layer.shadowColor = SideMenuManager.menuShadowColor.cgColor
            mainViewController.view.layer.shadowRadius = SideMenuManager.menuShadowRadius
            mainViewController.view.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
            mainViewController.view.layer.shadowOffset = CGSize(width: 0, height: 0)
            let direction:CGFloat = SideMenuTransition.presentDirection == .left ? 1 : -1
            mainViewController.view.frame.origin.x = direction * (menuView.frame.width)
            
        case .menuSlideIn, .menuDissolveIn:
            if SideMenuManager.menuBlurEffectStyle == nil {
                menuView.layer.shadowColor = SideMenuManager.menuShadowColor.cgColor
                menuView.layer.shadowRadius = SideMenuManager.menuShadowRadius
                menuView.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
                menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
            }
            mainViewController.view.frame.origin.x = 0
        }
        
        if SideMenuManager.menuPresentMode != .viewSlideOut {
            mainViewController.view.transform = CGAffineTransform(scaleX: SideMenuManager.menuAnimationTransformScaleFactor, y: SideMenuManager.menuAnimationTransformScaleFactor)
            if SideMenuManager.menuAnimationTransformScaleFactor > 1 {
                SideMenuTransition.tapView?.transform = mainViewController.view.transform
            }
            mainViewController.view.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
        }
    }
    
    internal class func presentMenuComplete() {
        guard let mainViewController = presentingViewControllerForMenu else {
            return
        }
      
        switch SideMenuManager.menuPresentMode {
        case .menuSlideIn, .menuDissolveIn, .viewSlideInOut:
            if SideMenuManager.menuParallaxStrength != 0 {
                let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                horizontal.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                horizontal.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                vertical.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                vertical.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [horizontal, vertical]
                mainViewController.view.addMotionEffect(group)
            }
        case .viewSlideOut: break;
        }
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = false
        }
    }
    
    internal func handleNotification(notification: NSNotification) {
        guard let mainViewController = SideMenuTransition.presentingViewControllerForMenu,
            let menuViewController = SideMenuTransition.viewControllerForMenu,
            menuViewController.presentedViewController == nil && menuViewController.presentingViewController != nil else {
                return
        }
        
        if let originalSuperview = SideMenuTransition.originalSuperview {
            originalSuperview.addSubview(mainViewController.view)
        }
        
        if notification.name == NSNotification.Name.UIApplicationDidEnterBackground {
            SideMenuTransition.hideMenuStart()
            SideMenuTransition.hideMenuComplete()
            menuViewController.dismiss(animated: false, completion: nil)
            return
        }
        
        UIView.animate(withDuration: SideMenuManager.menuAnimationDismissDuration,
                       delay: 0,
                       usingSpringWithDamping: SideMenuManager.menuAnimationUsingSpringWithDamping,
                       initialSpringVelocity: SideMenuManager.menuAnimationInitialSpringVelocity,
                       options: SideMenuManager.menuAnimationOptions,
                       animations: {
                        SideMenuTransition.hideMenuStart()
        }) { (finished) -> Void in
            SideMenuTransition.hideMenuComplete()
            menuViewController.dismiss(animated: false, completion: nil)
        }
    }
    
}

extension SideMenuTransition: UIViewControllerAnimatedTransitioning {
    
    // animate a change from one viewcontroller to another
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView
        // prevent any other menu gestures from firing
        container.isUserInteractionEnabled = false
        
        if let menuBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
            container.backgroundColor = menuBackgroundColor
        }
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let menuViewController = presenting ? toViewController : fromViewController
        let topViewController = presenting ? fromViewController : toViewController
        
        let menuView = menuViewController.view!
        let topView = topViewController.view!
        
        // prepare menu items to slide in
        if presenting {
            SideMenuTransition.originalSuperview = topView.superview
            
            // add the both views to our view controller
            switch SideMenuManager.menuPresentMode {
            case .viewSlideOut, .viewSlideInOut:
                container.addSubview(menuView)
                container.addSubview(topView)
            case .menuSlideIn, .menuDissolveIn:
                container.addSubview(topView)
                container.addSubview(menuView)
            }

            if SideMenuManager.menuFadeStatusBar {
                let statusBarView = UIView()
                SideMenuTransition.statusBarView = statusBarView
                container.addSubview(statusBarView)
            }
            
            SideMenuTransition.hideMenuStart()
        }
        
        let animate = {
            if self.presenting {
                SideMenuTransition.presentMenuStart()
            } else {
                SideMenuTransition.hideMenuStart()
            }
        }
        
        let complete = {
            container.isUserInteractionEnabled = true
            
            // tell our transitionContext object that we've finished animating
            if transitionContext.transitionWasCancelled {
                let viewControllerForPresentedMenu = SideMenuTransition.presentingViewControllerForMenu
                
                if self.presenting {
                    SideMenuTransition.hideMenuComplete()
                } else {
                    SideMenuTransition.presentMenuComplete()
                }
                
                transitionContext.completeTransition(false)
                
                if SideMenuTransition.switchMenus {
                    SideMenuTransition.switchMenus = false
                    viewControllerForPresentedMenu?.present(SideMenuTransition.viewControllerForMenu!, animated: true, completion: nil)
                }
                
                return
            }
            
            if self.presenting {
                SideMenuTransition.presentMenuComplete()
                transitionContext.completeTransition(true)
                switch SideMenuManager.menuPresentMode {
                case .viewSlideOut, .viewSlideInOut:
                    container.addSubview(topView)
                case .menuSlideIn, .menuDissolveIn:
                    container.insertSubview(topView, at: 0)
                }
                if !SideMenuManager.menuPresentingViewControllerUserInteractionEnabled {
                    let tapView = UIView()
                    container.insertSubview(tapView, aboveSubview: topView)
                    tapView.bounds = container.bounds
                    tapView.center = topView.center
                    if SideMenuManager.menuAnimationTransformScaleFactor > 1 {
                        tapView.transform = topView.transform
                    }
                    SideMenuTransition.tapView = tapView
                }
                if let statusBarView = SideMenuTransition.statusBarView {
                    container.bringSubview(toFront: statusBarView)
                }
                
                return
            }
            
            SideMenuTransition.hideMenuComplete()
            transitionContext.completeTransition(true)
            menuView.removeFromSuperview()
        }
        
        // perform the animation!
        let duration = transitionDuration(using: transitionContext)
        if interactive {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                            animate()
            }, completion: { (finished) in
                complete()
            })
        } else {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: SideMenuManager.menuAnimationUsingSpringWithDamping,
                           initialSpringVelocity: SideMenuManager.menuAnimationInitialSpringVelocity,
                           options: SideMenuManager.menuAnimationOptions,
                           animations: {
                            animate()
            }) { (finished) -> Void in
                complete()
            }
        }
    }
    
    // return how many seconds the transiton animation will take
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if interactive {
            return SideMenuManager.menuAnimationCompleteGestureDuration
        }
        return presenting ? SideMenuManager.menuAnimationPresentDuration : SideMenuManager.menuAnimationDismissDuration
    }
    
}

extension SideMenuTransition: UIViewControllerTransitioningDelegate {
    
    // return the animator when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        SideMenuTransition.presentDirection = presented == SideMenuManager.menuLeftNavigationController ? .left : .right
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presenting = false
        return self
    }
    
    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if our interactive flag is true, return the transition manager object
        // otherwise return nil
        return interactive ? SideMenuTransition.singleton : nil
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? SideMenuTransition.singleton : nil
    }
    
}
