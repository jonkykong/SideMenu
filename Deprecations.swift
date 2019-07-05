//
//  Deprecations.swift
//  SideMenu
//
//  Created by Jon Kent on 7/3/19.
//

// Deprecations; to be removed at a future date.
extension SideMenuManager {
    
    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuPresentMode: SideMenuPresentStyle {
        get { return .viewSlideOut }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuPushStyle: MenuPushStyle {
        get { return .default }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAllowPushOfSameClassTwice: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuWidth: CGFloat {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationPresentDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationDismissDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationCompleteGestureDuration: Double {
        get { return 0.35 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationFadeStrength: CGFloat {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationTransformScaleFactor: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationBackgroundColor: UIColor? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuShadowOpacity: Float {
        get { return 0.5 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuShadowColor: UIColor {
        get { return .black }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuShadowRadius: CGFloat {
        get { return 5 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuPresentingViewControllerUserInteractionEnabled: Bool {
        get { return false }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuParallaxStrength: Int {
        get { return 0 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuFadeStatusBar: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationOptions: UIView.AnimationOptions {
        get { return .curveEaseInOut }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationCompletionCurve: UIView.AnimationCurve {
        get { return .easeIn }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationUsingSpringWithDamping: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAnimationInitialSpringVelocity: CGFloat {
        get { return 1 }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuDismissOnPush: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuAlwaysAnimate: Bool {
        get { return false }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuDismissWhenBackgrounded: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuBlurEffectStyle: UIBlurEffect.Style? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
        get { return nil }
        set {}
    }

    @available(*, deprecated, message: "This property has been moved to the UISideMenuNavigationController class.")
    public var menuEnableSwipeGestures: Bool {
        get { return true }
        set {}
    }

    @available(*, deprecated, renamed: "SideMenuPresentStyle")
    public typealias MenuPresentMode = SideMenuPresentStyle
}

extension SideMenuPresentStyle {
    @available(*, deprecated, renamed: "viewSlideOutMenuIn")
    public static let viewSlideInOut = viewSlideOutMenuIn
}
