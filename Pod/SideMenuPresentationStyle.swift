//
//  SideMenuPresentStyle.swift
//  SideMenu
//
//  Created by Jon Kent on 7/2/19.
//

import UIKit

@objcMembers
open class SideMenuPresentationStyle: InitializableClass {
    /// Background color behind the views and status bar color
    public var backgroundColor: UIColor = .black
    /// The starting alpha value of the menu before it appears
    public var menuStartAlpha: CGFloat = 1
    /// Whether or not the menu is on top. If false, the presenting view is on top. Shadows are applied to the view on top.
    public var menuOnTop: Bool = false
    /// The amount the menu is translated along the x-axis. Zero is stationary, negative values are off-screen, positive values are on screen.
    public var menuTranslateFactor: CGFloat = 0
    /// The amount the menu is scaled. Less than one shrinks the view, larger than one grows the view.
    public var menuScaleFactor: CGFloat = 1
    /// The color of the shadow applied to the top most view.
    public var onTopShadowColor: UIColor = .black
    /// The radius of the shadow applied to the top most view.
    public var onTopShadowRadius: CGFloat = 5
    /// The opacity of the shadow applied to the top most view.
    public var onTopShadowOpacity: Float = 0
    /// The offset of the shadow applied to the top most view.
    public var onTopShadowOffset: CGSize = .zero
    /// The ending alpha of the presenting view when the menu is fully displayed.
    public var presentingEndAlpha: CGFloat = 1
    /// The amount the presenting view is translated along the x-axis. Zero is stationary, negative values are off-screen, positive values are on screen.
    public var presentingTranslateFactor: CGFloat = 0
    /// The amount the presenting view is scaled. Less than one shrinks the view, larger than one grows the view.
    public var presentingScaleFactor: CGFloat = 1
    /// The strength of the parallax effect on the presenting view once the menu is displayed.
    public var presentingParallaxStrength: CGSize = .zero

    required public init() {}

    /// This method is called just before the presentation transition begins. Use this to setup any animations. The super method does not need to be called.
    func presentationTransitionWillBegin(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {}
    /// This method is called during the presentation animation. Use this to animate anything alongside the menu animation. The super method does not need to be called.
    func presentationTransition(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {}
    /// This method is called when the presentation transition ends. Use this to finish any animations. The super method does not need to be called.
    func presentationTransitionDidEnd(to presentedViewController: UIViewController, from presentingViewController: UIViewController, _ completed: Bool) {}
    /// This method is called just before the dismissal transition begins. Use this to setup any animations. The super method does not need to be called.
    func dismissalTransitionWillBegin(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {}
    /// This method is called during the dismissal animation. Use this to animate anything alongside the menu animation. The super method does not need to be called.
    func dismissalTransition(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {}
    /// This method is called when the dismissal transition ends. Use this to finish any animations. The super method does not need to be called.
    func dismissalTransitionDidEnd(to presentedViewController: UIViewController, from presentingViewController: UIViewController, _ completed: Bool) {}
}

public extension SideMenuPresentationStyle {
    /// Menu slides in over the existing view.
    static var menuSlideIn: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuOnTop = true
            $0.menuTranslateFactor = -1
        }
    }
    /// The existing view slides out to reveal the menu underneath.
    static var viewSlideOut: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.presentingTranslateFactor = 1
        }
    }
    /// The existing view slides out while the menu slides in.
    static var viewSlideOutMenuIn: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuTranslateFactor = -1
            $0.presentingTranslateFactor = 1
        }
    }
    /// The menu dissolves in over the existing view.
    static var menuDissolveIn: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuStartAlpha = 0
            $0.menuOnTop = true
        }
    }
    /// The existing view slides out while the menu partially slides in.
    static var viewSlideOutMenuPartialIn: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuTranslateFactor = -0.5
            $0.presentingTranslateFactor = 1
        }
    }
    /// The existing view slides out while the menu slides out from under it.
    static var viewSlideOutMenuOut: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuTranslateFactor = 1
            $0.presentingTranslateFactor = 1
        }
    }
    /// The existing view slides out while the menu partially slides out from under it.
    static var viewSlideOutMenuPartialOut: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.menuTranslateFactor = 0.5
            $0.presentingTranslateFactor = 1
        }
    }
    /// The existing view slides out and shrinks to reveal the menu underneath.
    static var viewSlideOutMenuZoom: SideMenuPresentationStyle {
        return SideMenuPresentationStyle {
            $0.presentingTranslateFactor = 1
            $0.menuScaleFactor = 0.95
            $0.menuOnTop = true
        }
    }
}
