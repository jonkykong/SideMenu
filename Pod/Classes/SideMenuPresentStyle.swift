//
//  SideMenuPresentStyle.swift
//  SideMenu
//
//  Created by Jon Kent on 7/2/19.
//

import Foundation

public protocol SideMenuPresentStyleDelegate {
    func presentationTransitionWillBegin()
    func presentationTransition()
    func presentationTransitionDidEnd(_ completed: Bool)
    func dismissalTransitionWillBegin()
    func dismissalTransition()
    func dismissalTransitionDidEnd(_ completed: Bool)
}

public struct SideMenuPresentStyle: SideMenuPresentStyleDelegate {

    public var backgroundColor: UIColor = .black
    public var menuStartAlpha: CGFloat = 1
    public var menuOnTop: Bool = false
    public var menuTranslateFactor: CGFloat = 0
    public var menuScaleFactor: CGFloat = 1
    public var onTopShadowColor: UIColor = .black
    public var onTopShadowRadius: CGFloat = 5
    public var onTopShadowOpacity: Float = 0.5
    public var onTopShadowOffset: CGSize = .zero
    public var presentingEndAlpha: CGFloat = 1
    public var presentingTranslateFactor: CGFloat = 0
    public var presentingScaleFactor: CGFloat = 1
    public var presentingParallaxStrength: CGSize = .zero

    public init() {}

    public init(_ block: (inout SideMenuPresentStyle) -> Void) {
        self.init()
        block(&self)
    }

    // Override with custom behaviors if desired
    public func presentationTransitionWillBegin() {}
    public func presentationTransition() {}
    public func presentationTransitionDidEnd(_ completed: Bool) {}
    public func dismissalTransitionWillBegin() {}
    public func dismissalTransition() {}
    public func dismissalTransitionDidEnd(_ completed: Bool) {}
}

public extension SideMenuPresentStyle {
    /// Menu slides in over the existing view.
    static let menuSlideIn = SideMenuPresentStyle {
        $0.menuOnTop = true
        $0.menuTranslateFactor = -1
    }
    /// The existing view slides out to reveal the menu underneath.
    static let viewSlideOut = SideMenuPresentStyle {
        $0.presentingTranslateFactor = 1
    }
    /// The existing view slides out while the menu slides in.
    static let viewSlideOutMenuIn = SideMenuPresentStyle {
        $0.menuTranslateFactor = -1
        $0.presentingTranslateFactor = 1
    }
    /// The menu dissolves in over the existing view.
    static let menuDissolveIn = SideMenuPresentStyle {
        $0.menuStartAlpha = 0
        $0.menuOnTop = true
    }
    /// The existing view slides out while the menu partially slides in.
    static let viewSlideOutMenuPartialIn = SideMenuPresentStyle {
        $0.menuTranslateFactor = -0.5
        $0.presentingTranslateFactor = 1
    }
    /// The existing view slides out while the menu slides out from under it.
    static let viewSlideOutMenuOut = SideMenuPresentStyle {
        $0.menuTranslateFactor = 1
        $0.presentingTranslateFactor = 1
    }
    /// The existing view slides out while the menu partially slides out from under it.
    static let viewSlideOutMenuPartialOut = SideMenuPresentStyle {
        $0.menuTranslateFactor = 0.5
        $0.presentingTranslateFactor = 1
    }
    /// The existing view slides out and shrinks to reveal the menu underneath.
    static let viewSlideOutMenuZoom = SideMenuPresentStyle {
        $0.presentingTranslateFactor = 1
        $0.menuScaleFactor = 0.95
        $0.menuOnTop = true
    }
}
