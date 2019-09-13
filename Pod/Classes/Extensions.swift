//
//  Extensions.swift
//  Pods-Example
//
//  Created by Jon Kent on 7/1/19.
//

import UIKit

extension NSObject: InitializableClass {}

internal extension UIView {

    @discardableResult func untransformed(_ block: () -> CGFloat) -> CGFloat {
        let t = self.transform
        transform = .identity
        let value = block()
        transform = t
        return value
    }

    func bringToFront() {
        superview?.bringSubviewToFront(self)
    }

    func untransform(_ block: () -> Void) {
        untransformed { () -> CGFloat in
            block()
            return 0
        }
    }

    static func animationsEnabled(_ block: () -> Void) {
        let a = areAnimationsEnabled
        setAnimationsEnabled(true)
        block()
        setAnimationsEnabled(a)
    }
}

internal extension UIViewController {

    var activeViewController: UIViewController {
        switch self {
        case let navigationController as UINavigationController:
            return navigationController.visibleViewController?.activeViewController ?? self
        case let tabBarController as UITabBarController:
            return tabBarController.selectedViewController?.activeViewController ?? self
        case let splitViewController as UISplitViewController:
            return splitViewController.viewControllers.last?.activeViewController ?? self
        default:
            return presentedViewController?.activeViewController ?? self
        }
    }

    @objc var isHidden: Bool {
        return presentingViewController == nil
    }
}

internal extension UIGestureRecognizer {

    convenience init(addTo view: UIView, target: Any, action: Selector) {
        self.init()
        addTarget(target, action: action)
        view.addGestureRecognizer(self)
    }

    convenience init?(addTo view: UIView?, target: Any, action: Selector) {
        guard let view = view else { return nil }
        self.init(addTo: view, target: target, action: action)
    }

    func remove() {
        view?.removeGestureRecognizer(self)
    }
}

internal extension UIPanGestureRecognizer {

    var canSwitch: Bool {
        return !(self is UIScreenEdgePanGestureRecognizer)
    }

    var xTranslation: CGFloat {
        return view?.untransformed {
            return self.translation(in: view).x
            } ?? 0
    }

    var xVelocity: CGFloat {
        return view?.untransformed {
            return self.velocity(in: view).x
            } ?? 0
    }
}
