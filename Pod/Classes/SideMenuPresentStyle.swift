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
    static let menuSlideIn = SideMenuPresentStyle {
        $0.menuOnTop = true
        $0.menuTranslateFactor = -1
    }
    static let viewSlideOut = SideMenuPresentStyle {
        $0.presentingTranslateFactor = 1
    }
    static let viewSlideOutMenuIn = SideMenuPresentStyle {
        $0.menuTranslateFactor = -1
        $0.presentingTranslateFactor = 1
    }
    static let menuDissolveIn = SideMenuPresentStyle {
        $0.menuStartAlpha = 0
        $0.menuOnTop = true
    }
    static let viewSlideOutMenuPartialIn = SideMenuPresentStyle {
        $0.menuTranslateFactor = -0.5
        $0.presentingTranslateFactor = 1
    }
    static let viewSlideOutMenuOut = SideMenuPresentStyle {
        $0.menuTranslateFactor = 1
        $0.presentingTranslateFactor = 1
    }
    static let viewSlideOutMenuPartialOut = SideMenuPresentStyle {
        $0.menuTranslateFactor = 0.5
        $0.presentingTranslateFactor = 1
    }
    static let viewSlideOutMenuZoom = SideMenuPresentStyle {
        $0.presentingTranslateFactor = 1
        $0.menuScaleFactor = 0.95
    }
}
