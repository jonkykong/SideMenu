//
//  Deprecations.swift
//  SideMenu
//
//  Created by Jon Kent on 7/3/19.
//

import UIKit

// Deprecations; to be removed at a future date.
extension SideMenuManager {

    @available(*, deprecated, renamed: "leftMenuNavigationController")
    open var menuLeftNavigationController: SideMenuNavigationController? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, renamed: "rightMenuNavigationController")
    open var menuRightNavigationController: SideMenuNavigationController? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuPresentMode: SideMenuPresentationStyle {
        get { return .viewSlideOut }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuPushStyle: SideMenuPushStyle {
        get { return .default }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAllowPushOfSameClassTwice: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuWidth: CGFloat {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationPresentDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationDismissDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationCompleteGestureDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuAnimationFadeStrength: CGFloat {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuAnimationTransformScaleFactor: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuAnimationBackgroundColor: UIColor? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuShadowOpacity: Float {
        get { return 0.5 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuShadowColor: UIColor {
        get { return .black }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuShadowRadius: CGFloat {
        get { return 5 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuPresentingViewControllerUserInteractionEnabled: Bool {
        get { return false }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuPresentationStyle class.")
    public var menuParallaxStrength: Int {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuFadeStatusBar: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationOptions: UIView.AnimationOptions {
        get { return .curveEaseInOut }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationCompletionCurve: UIView.AnimationCurve {
        get { return .easeIn }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationUsingSpringWithDamping: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAnimationInitialSpringVelocity: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuDismissOnPush: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuAlwaysAnimate: Bool {
        get { return false }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuDismissWhenBackgrounded: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuBlurEffectStyle: UIBlurEffect.Style? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the SideMenuNavigationController class.")
    public var menuEnableSwipeGestures: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, renamed: "enableSwipeToDismissGesture")
    public var enableSwipeGestures: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, renamed: "SideMenuPresentationStyle")
    public typealias MenuPresentMode = SideMenuPresentationStyle

    @available(*, deprecated, renamed: "addScreenEdgePanGesturesToPresent")
    @discardableResult public func menuAddScreenEdgePanGesturesToPresent(toView view: UIView, forMenu sides: [PresentDirection] = [.left, .right]) -> [UIScreenEdgePanGestureRecognizer] {
        return []
    }

    @available(*, deprecated, renamed: "addPanGestureToPresent")
    @discardableResult public func menuAddPanGestureToPresent(toView view: UIView) -> UIPanGestureRecognizer {
        return UIPanGestureRecognizer()
    }
}

extension SideMenuPresentationStyle {
    @available(*, deprecated, renamed: "viewSlideOutMenuIn")
    public static var viewSlideInOut: SideMenuPresentationStyle { return viewSlideOutMenuIn }
}

@available(*, deprecated, renamed: "SideMenuNavigationController")
public typealias UISideMenuNavigationController = SideMenuNavigationController

@available(*, deprecated, renamed: "SideMenuNavigationControllerDelegate")
public typealias UISideMenuNavigationControllerDelegate = SideMenuNavigationControllerDelegate
